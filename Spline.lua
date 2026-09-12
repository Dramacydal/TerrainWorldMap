-- Tiny Catmull-Rom spline helper -- there is no built-in curve-drawing
-- primitive in the WoW UI API (Frame:CreateLine only does straight
-- segments, same as Blizzard's own talent-tree connectors) and no
-- known community library for it either, so FlightPaths.lua's
-- "Shift = show real curved route" mode needs its own densification step
-- to turn Twm_taxipathnodes' sparse control points into a visually smooth
-- curve instead of a visibly jagged polyline.

-- Standard uniform Catmull-Rom through p1..p2, using p0/p3 as the curve's
-- tangent-defining neighbors (clamped to p1/p2 at a path's own ends, the
-- usual trick for an open, non-looping curve).
local function CatmullRomPoint(p0, p1, p2, p3, t)
    local t2, t3 = t * t, t * t * t;
    local x = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t
        + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2
        + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3);
    local y = 0.5 * ((2 * p1[2]) + (-p0[2] + p2[2]) * t
        + (2 * p0[2] - 5 * p1[2] + 4 * p2[2] - p3[2]) * t2
        + (-p0[2] + 3 * p1[2] - 3 * p2[2] + p3[2]) * t3);
    return x, y;
end

-- Angle (0..pi) between the segment arriving at points[i] and the one
-- leaving it -- 0 means points[i-1]/points[i]/points[i+1] are already
-- collinear (no visible kink there to smooth), pi means the path folds
-- straight back on itself. 0 for either endpoint of the whole path (no
-- "arriving" or "leaving" segment to compare there).
local function KnotSharpness(points, i)
    local n = #points;
    if(i <= 1 or i >= n) then return 0; end
    local v1x, v1y = points[i][1] - points[i - 1][1], points[i][2] - points[i - 1][2];
    local v2x, v2y = points[i + 1][1] - points[i][1], points[i + 1][2] - points[i][2];
    local len1, len2 = math.sqrt(v1x * v1x + v1y * v1y), math.sqrt(v2x * v2x + v2y * v2y);
    if(len1 <= 0 or len2 <= 0) then return 0; end
    local cosT = (v1x * v2x + v1y * v2y) / (len1 * len2);
    cosT = math.max(-1, math.min(1, cosT));
    return math.acos(cosT);
end

-- points: ordered {x, y} list (e.g. one Twm_taxipathnodes[pathID] entry).
-- maxExtraPerSegment: Settings.lua slider value -- the number of extra
-- points added to whichever segment needs it most. A segment's own share
-- is the GREATER of two ratios: its length relative to the path's longest
-- segment, and the sharpest of its two end knots' turn angle relative to
-- the path's sharpest knot overall. Length alone would starve a short
-- segment sitting right next to a sharp turn -- it'd get few points just
-- for being short, even though that's exactly where the polyline needs the
-- most smoothing; folding the knot-angle ratio in guarantees the segment(s)
-- bordering the path's sharpest corner always get the full slider value,
-- regardless of how short they are, the same way the single longest
-- segment already does on length alone.
function TWM_CatmullRomInterpolate(points, maxExtraPerSegment)
    local n = points and #points or 0;
    if(not maxExtraPerSegment or maxExtraPerSegment <= 0 or n < 3) then
        return points;
    end

    local lengths, maxLen = {}, 0;
    for i = 1, n - 1 do
        local dx, dy = points[i + 1][1] - points[i][1], points[i + 1][2] - points[i][2];
        local len = math.sqrt(dx * dx + dy * dy);
        lengths[i] = len;
        if(len > maxLen) then maxLen = len; end
    end
    if(maxLen <= 0) then return points; end

    local sharpness, maxSharpness = {}, 0;
    for i = 1, n do
        local s = KnotSharpness(points, i);
        sharpness[i] = s;
        if(s > maxSharpness) then maxSharpness = s; end
    end

    local out = {};
    for i = 1, n - 1 do
        local p0 = points[i - 1] or points[i];
        local p1 = points[i];
        local p2 = points[i + 1];
        local p3 = points[i + 2] or points[i + 1];
        tinsert(out, p1);

        local weight = lengths[i] / maxLen;
        if(maxSharpness > 0) then
            local sharpWeight = math.max(sharpness[i], sharpness[i + 1]) / maxSharpness;
            weight = math.max(weight, sharpWeight);
        end

        local extra = math.floor(maxExtraPerSegment * weight + 0.5);
        local steps = extra + 1;
        for s = 1, extra do
            local x, y = CatmullRomPoint(p0, p1, p2, p3, s / steps);
            tinsert(out, {x, y});
        end
    end
    tinsert(out, points[n]);
    return out;
end
