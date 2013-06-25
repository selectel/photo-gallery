var ejs = require('ejs'),
    fs = require('fs'),
    index = fs.readFileSync('./index.ejs', 'utf8');

fs.writeFileSync('./index.min.html', ejs.render(index, {fs: fs}));