const fs = require('fs');

const url = process.env.SUPABASE_URL || '';
const key = process.env.SUPABASE_ANON_KEY || '';

if (!url || !key) {
  console.error('ERROR: Faltan variables de entorno SUPABASE_URL y SUPABASE_ANON_KEY');
  process.exit(1);
}

const html = fs.readFileSync('index.html', 'utf8')
  .replace(/%%SUPABASE_URL%%/g, url)
  .replace(/%%SUPABASE_ANON_KEY%%/g, key);

fs.mkdirSync('dist', { recursive: true });
fs.writeFileSync('dist/index.html', html);
console.log('Build completado → dist/index.html');
