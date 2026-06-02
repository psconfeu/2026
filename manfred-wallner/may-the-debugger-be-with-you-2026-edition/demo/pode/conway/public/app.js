

const els = {
    width: document.getElementById('width'),
    height: document.getElementById('height'),
    density: document.getElementById('density'),
    seed: document.getElementById('seed'),
    intervalMs: document.getElementById('intervalMs'),
    wrap: document.getElementById('wrap'),
    reset: document.getElementById('reset'),
    step: document.getElementById('step'),
    run: document.getElementById('run'),
    stop: document.getElementById('stop'),
    generation: document.getElementById('generation'),
    size: document.getElementById('size'),
    status: document.getElementById('status'),
    board: document.getElementById('board')
};

const ctx = els.board.getContext('2d');
let state = null;
let loop = null;
let tickInFlight = false;

function getRunIntervalMs() {
    const parsed = Number.parseInt(els.intervalMs.value, 10);
    if (!Number.isFinite(parsed)) {
        return 80;
    }

    return Math.max(20, Math.min(5000, parsed));
}

async function postJson(path, payload) {
    const response = await fetch(path, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });

    if (!response.ok) {
        const message = await response.text();
        throw new Error(message || `HTTP ${response.status}`);
    }

    return response.json();
}

async function getState() {
    const response = await fetch('/api/state');
    if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
    }
    return response.json();
}

function resizeCanvas() {
    const dpr = window.devicePixelRatio || 1;
    const rect = els.board.getBoundingClientRect();

    els.board.width = Math.max(1, Math.floor(rect.width * dpr));
    els.board.height = Math.max(1, Math.floor(rect.height * dpr));
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}

function showGameOverOverlay() {
    let overlay = document.getElementById('gameover-overlay');
    if (!overlay) {
        overlay = document.createElement('div');
        overlay.id = 'gameover-overlay';
        overlay.style.position = 'fixed';
        overlay.style.top = 0;
        overlay.style.left = 0;
        overlay.style.width = '100vw';
        overlay.style.height = '100vh';
        overlay.style.background = 'rgba(0,0,0,0.7)';
        overlay.style.color = 'white';
        overlay.style.display = 'flex';
        overlay.style.alignItems = 'center';
        overlay.style.justifyContent = 'center';
        overlay.style.fontSize = '4em';
        overlay.style.zIndex = 9999;
        overlay.style.cursor = 'pointer';
        overlay.innerText = 'GAME OVER\n\nClick to restart';
        overlay.onclick = async () => {
            overlay.style.display = 'none';
            try {
                stopLoop();
                await resetBoard();
            } catch (error) {
                updateStatus(error.message);
            }
        };
        document.body.appendChild(overlay);
    } else {
        overlay.style.display = 'flex';
    }
}

function hideGameOverOverlay() {
    let overlay = document.getElementById('gameover-overlay');
    if (overlay) overlay.style.display = 'none';
}

function drawBoard(current) {
    if (!current) {
        hideGameOverOverlay();
        return;
    }

    if (current.gameOver) {
        showGameOverOverlay();
    } else {
        hideGameOverOverlay();
    }

    const width = current.width;
    const height = current.height;
    const rows = Array.isArray(current.rows) ? current.rows : [];

    const w = els.board.clientWidth;
    const h = els.board.clientHeight;

    ctx.clearRect(0, 0, w, h);

    const cellW = w / width;
    const cellH = h / height;

    ctx.fillStyle = '#162028';
    ctx.fillRect(0, 0, w, h);

    ctx.strokeStyle = '#21343f';
    ctx.lineWidth = 1;

    for (let y = 0; y < height; y++) {
        const row = (typeof rows[y] === 'string') ? rows[y] : '';
        for (let x = 0; x < width; x++) {
            if (row[x] === '1') {
                ctx.fillStyle = '#49e2a9';
                ctx.fillRect(x * cellW, y * cellH, cellW, cellH);
            }

            if (cellW >= 8 && cellH >= 8) {
                ctx.strokeRect(x * cellW, y * cellH, cellW, cellH);
            }
        }
    }

    els.generation.textContent = `Gen: ${current.generation}`;
    els.size.textContent = `Size: ${width}x${height}`;
}

function updateStatus(message) {
    els.status.textContent = message;
}

async function refresh() {
    state = await getState();
    drawBoard(state);
}

function currentPayloadFromInputs() {
    return {
        width: Number.parseInt(els.width.value, 10),
        height: Number.parseInt(els.height.value, 10),
        density: Number.parseFloat(els.density.value),
        seed: Number.parseInt(els.seed.value, 10),
        wrap: els.wrap.checked
    };
}

async function resetBoard() {
    updateStatus('Resetting');
    state = await postJson('/api/reset', currentPayloadFromInputs());
    drawBoard(state);
    updateStatus('Idle');
}

async function stepBoard(steps = 1) {
    state = await postJson('/api/step', { steps });
    drawBoard(state);
}

async function runLoop() {
    if (loop) {
        return;
    }

    const intervalMs = getRunIntervalMs();

    loop = setInterval(async () => {
        if (tickInFlight) {
            return;
        }

        tickInFlight = true;
        try {
            await stepBoard(1);
            updateStatus(`Running (${intervalMs}ms)`);
        }
        catch (error) {
            stopLoop();
            updateStatus(error.message);
        }
        finally {
            tickInFlight = false;
        }
    }, intervalMs);

    els.run.disabled = true;
    els.stop.disabled = false;
    updateStatus(`Running (${intervalMs}ms)`);
}

function stopLoop() {
    if (loop) {
        clearInterval(loop);
        loop = null;
    }

    tickInFlight = false;

    els.run.disabled = false;
    els.stop.disabled = true;
    updateStatus('Idle');
}

function boardCoordinatesFromEvent(event) {
    if (!state) {
        return null;
    }

    const rect = els.board.getBoundingClientRect();
    const x = Math.floor(((event.clientX - rect.left) / rect.width) * state.width);
    const y = Math.floor(((event.clientY - rect.top) / rect.height) * state.height);

    if (x < 0 || x >= state.width || y < 0 || y >= state.height) {
        return null;
    }

    return { x, y };
}

async function toggleCell(event) {
    const point = boardCoordinatesFromEvent(event);
    if (!point) {
        return;
    }

    state = await postJson('/api/toggle', point);
    drawBoard(state);
}

els.reset.addEventListener('click', async () => {
    try {
        stopLoop();
        await resetBoard();
    }
    catch (error) {
        updateStatus(error.message);
    }
});

els.step.addEventListener('click', async () => {
    try {
        await stepBoard(1);
        updateStatus('Idle');
    }
    catch (error) {
        updateStatus(error.message);
    }
});

els.run.addEventListener('click', () => {
    runLoop().catch((error) => updateStatus(error.message));
});

els.stop.addEventListener('click', () => {
    stopLoop();
});

els.board.addEventListener('click', async (event) => {
    try {
        await toggleCell(event);
    }
    catch (error) {
        updateStatus(error.message);
    }
});

window.addEventListener('resize', () => {
    resizeCanvas();
    drawBoard(state);
});

(async () => {
    try {
        resizeCanvas();
        await refresh();
        updateStatus('Idle');
    }
    catch (error) {
        updateStatus(error.message);
    }
})();
