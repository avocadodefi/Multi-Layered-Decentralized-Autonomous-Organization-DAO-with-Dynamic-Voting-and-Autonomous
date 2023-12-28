const fs = require('fs').promises;

async function main() {
    const wasmFile = './dist/zksync-crypto-web_bg.wasm';
    const jsFile = './dist/zksync-crypto-web.js';
    const asmJsFile = './zksync-crypto-bundler_asm.js';

    const brokenStrings = [
        `input = import.meta.url.replace`,
        `input = new URL`
    ];

    try {
        const wasmData = await fs.readFile(wasmFile);
        let jsCode = (await fs.readFile(jsFile)).toString();

        // Commenting out broken strings
        brokenStrings.forEach((str) => {
            jsCode = jsCode.replace(new RegExp(str, 'g'), '// ' + str);
        });

        // Adding base64 encoded WASM and utility functions
        jsCode += `
const base64WasmCode = \`${wasmData.toString('base64')}\`;

function base64ToArrayBuffer(base64) {
    const binaryString = window.atob(base64);
    const length = binaryString.length;
    const bytes = new Uint8Array(length);

    for (let i = 0; i < length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
}

const wasmBytes = base64ToArrayBuffer(base64WasmCode);

const wasmResponseInit = {
    "status" : 200 ,
    "statusText" : "ok.",
    headers: {
        'Content-Type': 'application/wasm',
        'Content-Length': wasmBytes.length
    }
};

export function wasmSupported() {
    try {
        if (typeof WebAssembly === 'object') {
            return true;
        }
    } catch (e) {}
    return false;
}

export async function loadZkSyncCrypto(wasmFileUrl) {
    if (!wasmSupported()) {
        return require('${asmJsFile}');
    }
    if (!wasmFileUrl) {
        const wasmResponse = new Response(wasmBytes, wasmResponseInit);
        await init(wasmResponse);
    } else {
        await init(wasmFileUrl);
    }
}
`;
        await fs.writeFile(jsFile, jsCode);
    } catch (error) {
        console.error('Error occurred:', error);
    }
}

main();
