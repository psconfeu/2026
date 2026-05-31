'use strict';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
let selectedPlayers = new Set();
let pollInterval = null;
let previousRanks = new Map();
let gameSpeedDelayMs = 0;
let lastErrorText = '';

const UI_POLL_INTERVAL_MS = 1000;
const GAME_SPEED_KEY = 'maze-loot-game-speed-delay-ms';

class ApiError extends Error {
    constructor(message, status = null) {
        super(message);
        this.name = 'ApiError';
        this.status = status;
    }
}

async function requestJson(url, options = null) {
    let response;
    try {
        response = await fetch(url, options || undefined);
    }
    catch {
        throw new ApiError('Endpoint did not respond');
    }

    const responseText = await response.text();
    let parsed = null;
    if (responseText) {
        try {
            parsed = JSON.parse(responseText);
        }
        catch {
            parsed = null;
        }
    }

    if (!response.ok) {
        const message = (parsed && (parsed.error || parsed.message))
            ? (parsed.error || parsed.message)
            : (response.statusText || 'Request failed');
        throw new ApiError(message, response.status);
    }

    return parsed || {};
}

function formatErrorMessage(error, prefix) {
    const statusPart = (error && Number.isInteger(error.status)) ? ` (HTTP ${error.status})` : '';
    const detail = (error && error.message) ? error.message : 'Unknown error';
    return `${prefix}${statusPart}: ${detail}`;
}

function showError(message) {
    if (!message || message === lastErrorText) {
        return;
    }

    const box = document.getElementById('errorBox');
    box.textContent = message;
    box.style.display = 'block';
    lastErrorText = message;
}

function hideError() {
    const box = document.getElementById('errorBox');
    box.textContent = '';
    box.style.display = 'none';
    lastErrorText = '';
}

// ---------------------------------------------------------------------------
// Boot
// ---------------------------------------------------------------------------
async function init() {
    initializeGameSpeed();

    try {
        const data = await requestJson('/api/characters');
        renderCharacters(data.characters);

        // Re-sync UI in case server already has a game running (e.g. page refresh)
        await refreshStatus();
        hideError();
    }
    catch (error) {
        showError(formatErrorMessage(error, 'Failed to load app state'));
    }
}

// ---------------------------------------------------------------------------
// Character grid
// ---------------------------------------------------------------------------
function renderCharacters(characters) {
    const container = document.getElementById('characters');
    container.innerHTML = '';
    for (const name of characters) {
        const btn = document.createElement('button');
        btn.className = 'char-btn';
        btn.textContent = name;
        btn.dataset.name = name;
        btn.addEventListener('click', () => toggleCharacter(btn, name));
        container.appendChild(btn);
    }
}

function toggleCharacter(btn, name) {
    if (selectedPlayers.has(name)) {
        selectedPlayers.delete(name);
        btn.classList.remove('selected');
    } else {
        selectedPlayers.add(name);
        btn.classList.add('selected');
    }
}

function initializeGameSpeed() {
    const input = document.getElementById('gameSpeedDelayMs');
    const saved = Number.parseInt(localStorage.getItem(GAME_SPEED_KEY), 10);

    if (Number.isFinite(saved) && saved >= 10 && saved <= 1000) {
        gameSpeedDelayMs = saved;
    }

    input.value = String(gameSpeedDelayMs);
    updateGameSpeedLabel();

    input.addEventListener('input', async () => {
        const next = Number.parseInt(input.value, 10);
        if (!Number.isFinite(next)) {
            return;
        }

        gameSpeedDelayMs = next;
        localStorage.setItem(GAME_SPEED_KEY, String(gameSpeedDelayMs));
        updateGameSpeedLabel();
        await setGameSpeed(gameSpeedDelayMs);
    });
}

function updateGameSpeedLabel() {
    document.getElementById('gameSpeedDelayValue').textContent = `${gameSpeedDelayMs} ms`;
}

async function setGameSpeed(delayMs) {
    try {
        const data = await requestJson('/api/speed', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ delayMs })
        });
        if (Number.isFinite(data.delayMs)) {
            gameSpeedDelayMs = data.delayMs;
            localStorage.setItem(GAME_SPEED_KEY, String(gameSpeedDelayMs));
            document.getElementById('gameSpeedDelayMs').value = String(gameSpeedDelayMs);
            updateGameSpeedLabel();
        }
        hideError();
    }
    catch (error) {
        showError(formatErrorMessage(error, 'Speed update failed'));
    }
}

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------
document.getElementById('startBtn').addEventListener('click', async () => {
    if (selectedPlayers.size === 0) {
        showError('Start failed: Select at least one player first');
        return;
    }

    try {
        const data = await requestJson('/api/start', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ players: [...selectedPlayers] })
        });

        previousRanks = new Map();

        if (Number.isFinite(data.delayMs)) {
            gameSpeedDelayMs = data.delayMs;
            localStorage.setItem(GAME_SPEED_KEY, String(gameSpeedDelayMs));
            document.getElementById('gameSpeedDelayMs').value = String(gameSpeedDelayMs);
            updateGameSpeedLabel();
        }

        setUIState('running', data.totalItems);
        startPolling();
        hideError();
    }
    catch (error) {
        showError(formatErrorMessage(error, 'Start failed'));
    }
});

// ---------------------------------------------------------------------------
// Reset
// ---------------------------------------------------------------------------
document.getElementById('resetBtn').addEventListener('click', async () => {
    stopPolling();
    try {
        await requestJson('/api/reset', { method: 'POST' });
        previousRanks = new Map();

        // Clear character selection
        selectedPlayers.clear();
        document.querySelectorAll('.char-btn.selected')
            .forEach(b => b.classList.remove('selected'));

        setUIState('idle', 0);
        document.getElementById('resultsSection').style.display = 'none';
        updateProgress(0, 0);
        hideError();
    }
    catch (error) {
        showError(formatErrorMessage(error, 'Reset failed'));
    }
});

// ---------------------------------------------------------------------------
// UI state
// ---------------------------------------------------------------------------
function setUIState(status, total = 0) {
    const startBtn = document.getElementById('startBtn');
    const resetBtn = document.getElementById('resetBtn');
    const badge = document.getElementById('statusBadge');
    const progressWrap = document.getElementById('progressWrap');
    const selectPlayersSection = document.getElementById('selectPlayersSection');

    badge.className = 'status-badge status-' + status;
    badge.textContent = status.charAt(0).toUpperCase() + status.slice(1);
    selectPlayersSection.style.display = (status === 'running') ? 'none' : '';

    if (status === 'running') {
        startBtn.disabled = true;
        resetBtn.disabled = false;
        progressWrap.style.display = 'block';
        updateProgress(0, total);
    } else if (status === 'completed') {
        startBtn.disabled = false;
        resetBtn.disabled = false;
    } else {
        // idle
        startBtn.disabled = false;
        resetBtn.disabled = true;
        progressWrap.style.display = 'none';
    }
}

// ---------------------------------------------------------------------------
// Polling
// ---------------------------------------------------------------------------
function startPolling() {
    stopPolling();
    pollInterval = setInterval(poll, UI_POLL_INTERVAL_MS);
}

function stopPolling() {
    if (pollInterval !== null) {
        clearInterval(pollInterval);
        pollInterval = null;
    }
}

async function poll() {
    const data = await fetchStatus();
    if (!data) return;

    if (data.status === 'running') {
        const looted = data.totalItems - data.remainingItems;
        updateProgress(looted, data.totalItems);
        renderResults(data.results, true);
    } else if (data.status === 'completed') {
        stopPolling();
        updateProgress(data.totalItems, data.totalItems);
        setUIState('completed');
        renderResults(data.results, false);
    }
}

// ---------------------------------------------------------------------------
// Status helpers
// ---------------------------------------------------------------------------
async function fetchStatus() {
    try {
        const data = await requestJson('/api/status');
        hideError();
        return data;
    } catch (error) {
        showError(formatErrorMessage(error, 'Status update failed'));
        return null;
    }
}

async function refreshStatus() {
    const data = await fetchStatus();
    if (!data) return;

    if (Number.isFinite(data.delayMs)) {
        gameSpeedDelayMs = data.delayMs;
        localStorage.setItem(GAME_SPEED_KEY, String(gameSpeedDelayMs));
        document.getElementById('gameSpeedDelayMs').value = String(gameSpeedDelayMs);
        updateGameSpeedLabel();
    }

    setUIState(data.status, data.totalItems);

    if (data.status === 'running') {
        const looted = data.totalItems - data.remainingItems;
        updateProgress(looted, data.totalItems);
        startPolling();
        renderResults(data.results, true);
    } else if (data.status === 'completed') {
        updateProgress(data.totalItems, data.totalItems);
        renderResults(data.results, false);
    }
}

// ---------------------------------------------------------------------------
// Progress bar
// ---------------------------------------------------------------------------
function updateProgress(looted, total) {
    const bar = document.getElementById('progressBar');
    const label = document.getElementById('progressLabel');
    const pct = total > 0 ? (looted / total) * 100 : 0;
    bar.style.width = pct + '%';
    label.textContent = `${looted} / ${total} items looted`;
}

// ---------------------------------------------------------------------------
// Results table
// ---------------------------------------------------------------------------
function renderResults(results, live = false) {
    if (!results || results.length === 0) return;

    document.getElementById('rankingsHeading').textContent =
        live ? '📊 Live Rankings' : '🏆 Final Results';

    const tbody = document.getElementById('resultsBody');
    tbody.innerHTML = '';

    const currentRanks = new Map();
    results.forEach((r, i) => {
        currentRanks.set(r.name, i + 1);
    });

    results.forEach((r, i) => {
        const tr = document.createElement('tr');
        if (i === 0) tr.className = 'winner';

        let trendSymbol = '';
        let trendClass = 'trend-none';
        const previousRank = previousRanks.get(r.name);
        const currentRank = i + 1;

        if (live && Number.isInteger(previousRank)) {
            if (currentRank < previousRank) {
                trendSymbol = '▲';
                trendClass = 'trend-up';
            }
            else if (currentRank > previousRank) {
                trendSymbol = '▼';
                trendClass = 'trend-down';
            }
        }

        tr.innerHTML = `
            <td>${i === 0 ? '🏆' : i + 1}</td>
            <td>${r.name}</td>
            <td>${r.itemCount}</td>
            <td class="trend-cell ${trendClass}">${trendSymbol}</td>`;
        tbody.appendChild(tr);
    });

    if (live) {
        previousRanks = currentRanks;
    }

    document.getElementById('resultsSection').style.display = 'block';
}

// ---------------------------------------------------------------------------
init();
