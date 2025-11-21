const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

// KUNCI UTAMA:
// Karena file ini ada di dalam folder "build", kita set "rootDir" ke satu folder di atasnya.
// __dirname = D:\Roblox\WindUI\build
// rootDir   = D:\Roblox\WindUI
const rootDir = path.resolve(__dirname, '..');

// Konfigurasi
const mode = process.argv[2] || 'build';
// Ambil package.json dari rootDir
const packageJson = require(path.join(rootDir, 'package.json'));
const dateStr = new Date().toISOString().split('T')[0];

console.log(`[ ${new Date().toLocaleTimeString()} ] Starting build...`);

// 1. Buat file build/package.lua
// File ini akan disimpan di folder yang sama dengan script ini (__dirname)
try {
    const pkgContent = fs.readFileSync(path.join(rootDir, 'package.json'), 'utf-8');
    const packageLuaContent = `-- Generated from package.json | build/build.js\n\nreturn [[\n${pkgContent}\n]]`;
    
    fs.writeFileSync(path.join(__dirname, 'package.lua'), packageLuaContent);
} catch (e) {
    console.error('Failed to create package.lua:', e);
    process.exit(1);
}

// 2. Tentukan Input/Output
// Input ada di folder src (di root)
let inputFile = path.join(rootDir, 'src', 'Init.lua');
let prefix = '[ BUILD ]';

if (mode === 'dev') {
    inputFile = process.argv[3] || path.join(rootDir, 'main.lua');
    prefix = '[ DEV ]';
}

// Output ada di folder dist (di root)
const outputFile = path.join(rootDir, 'dist', 'main.lua');
// Config ada di folder build (di sini)
const configFile = path.join(__dirname, 'darklua.dev.config.json');
// Temp file ditaruh di dist
const tempFile = path.join(rootDir, 'dist', 'temp.lua');

// 3. Siapkan Header
try {
    // Header ada di folder build (__dirname)
    let header = fs.readFileSync(path.join(__dirname, 'header.lua'), 'utf-8');
    header = header.replace(/{{VERSION}}/g, packageJson.version || '')
                   .replace(/{{BUILD_DATE}}/g, dateStr)
                   .replace(/{{DESCRIPTION}}/g, packageJson.description || '')
                   .replace(/{{REPOSITORY}}/g, packageJson.repository || '')
                   .replace(/{{DISCORD}}/g, packageJson.discord || '')
                   .replace(/{{LICENSE}}/g, packageJson.license || '');
    
    // 4. Jalankan DarkLua
    const startTime = Date.now();
    console.log('Running DarkLua...');
    
    // Pastikan folder dist ada di root
    const distDir = path.join(rootDir, 'dist');
    if (!fs.existsSync(distDir)) fs.mkdirSync(distDir);
    
    // Jalankan perintah darklua (path harus dibungkus kutip agar aman dari spasi)
    execSync(`darklua process "${inputFile}" "${tempFile}" --config "${configFile}"`, { stdio: 'inherit', cwd: rootDir });
    
    const endTime = Date.now();
    const timeTaken = endTime - startTime;

    // 5. Gabungkan Header + Hasil DarkLua
    const tempLua = fs.readFileSync(tempFile, 'utf-8');
    const finalContent = `${header}\n\n${tempLua}`;
    
    fs.writeFileSync(outputFile, finalContent);
    fs.unlinkSync(tempFile); // Hapus file temp

    // 6. Hitung Ukuran File
    const stats = fs.statSync(outputFile);
    const sizeKB = Math.round(stats.size / 1024);

    // Output Sukses
    console.log(`\n[ ${new Date().toLocaleTimeString()} ]`);
    console.log(`[ ✓ ] ${prefix} Success`);
    console.log(`[ > ] Version: ${packageJson.version}`);
    console.log(`[ > ] Time taken: ${timeTaken}ms`);
    console.log(`[ > ] Size: ${sizeKB}KB`);
    console.log(`[ > ] Output file: ${outputFile}\n`);

} catch (error) {
    console.error('\n[ X ] Build Failed:', error.message);
    process.exit(1);
}