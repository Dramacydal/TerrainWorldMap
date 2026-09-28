const { PNG } = require('pngjs');
const fs = require('fs');
const [,, file, x0s, y0s, ws, hs, outSuffix] = process.argv;
const x0=+x0s,y0=+y0s,w=+ws,h=+hs;
const src = PNG.sync.read(fs.readFileSync(file));
const out = new PNG({width:w,height:h});
for (let y=0;y<h;y++) for (let x=0;x<w;x++){
  const sxr=x0+x, syr=y0+y;
  if (sxr<0||sxr>=src.width||syr<0||syr>=src.height) continue;
  const si=(syr*src.width+sxr)*4, di=(y*w+x)*4;
  out.data[di]=src.data[si];out.data[di+1]=src.data[si+1];out.data[di+2]=src.data[si+2];out.data[di+3]=255;
}
fs.writeFileSync(file.replace('.png', outSuffix+'.png'), PNG.sync.write(out));
