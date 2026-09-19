(function () {
    const resourceName = typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'zayko_ticketagratter';

    const app = document.getElementById('app');
    const storeScreen = document.getElementById('store-screen');
    const scratchScreen = document.getElementById('scratch-screen');
    const ticketList = document.getElementById('ticket-list');
    const storeError = document.getElementById('store-error');
    const storeCloseBtn = document.getElementById('store-close');
    const scratchCloseBtn = document.getElementById('scratch-close');
    const scratchTitle = document.getElementById('scratch-title');
    const grid = document.getElementById('grid');
    const revealAllBtn = document.getElementById('reveal-all-btn');
    const resultBanner = document.getElementById('result-banner');
    const resultText = document.getElementById('result-text');
    const resultContinueBtn = document.getElementById('result-continue-btn');

    const REVEAL_THRESHOLD = 0.55;
    const BRUSH_RADIUS = 18;
    let revealedCount = 0;
    let cellsRevealFns = [];

    function post(action, data) {
        return fetch(`https://${resourceName}/${action}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        }).catch(() => {});
    }

    function showApp() {
        app.classList.remove('hidden');
    }

    function hideApp() {
        app.classList.add('hidden');
    }

    function showScreen(screen) {
        storeScreen.classList.add('hidden');
        scratchScreen.classList.add('hidden');
        screen.classList.remove('hidden');
    }

    function renderTicket(ticket) {
        const legendHtml = ticket.legend.map((l) => `<span>${l.symbol} ${l.label}</span>`).join('');
        return `
            <div class="ticket-card">
                <div class="ticket-icon" style="background:${ticket.color}33;color:${ticket.color}">🎫</div>
                <div class="ticket-info">
                    <div class="name">${ticket.label}</div>
                    <div class="desc">${ticket.desc}</div>
                    <div class="ticket-legend">${legendHtml}</div>
                </div>
                <div class="ticket-buy">
                    <div class="price">${ticket.price}$</div>
                    <button data-id="${ticket.id}">Acheter</button>
                </div>
            </div>
        `;
    }

    function openStore(tickets) {
        storeError.classList.add('hidden');
        ticketList.innerHTML = tickets.map(renderTicket).join('');
        ticketList.querySelectorAll('button[data-id]').forEach((btn) => {
            btn.addEventListener('click', () => {
                ticketList.querySelectorAll('button[data-id]').forEach((b) => (b.disabled = true));
                storeError.classList.add('hidden');
                post('buyTicket', { id: btn.dataset.id });
            });
        });
        showApp();
        showScreen(storeScreen);
    }

    function buildCell(symbol) {
        const wrapper = document.createElement('div');
        wrapper.className = 'cell';

        const symbolCanvas = document.createElement('canvas');
        const foilCanvas = document.createElement('canvas');
        symbolCanvas.className = 'symbol-layer';
        foilCanvas.className = 'foil-layer';

        wrapper.appendChild(symbolCanvas);
        wrapper.appendChild(foilCanvas);

        const size = 140;
        [symbolCanvas, foilCanvas].forEach((c) => {
            c.width = size;
            c.height = size;
        });

        const sctx = symbolCanvas.getContext('2d');
        sctx.fillStyle = '#fff8e1';
        sctx.fillRect(0, 0, size, size);
        sctx.font = '64px sans-serif';
        sctx.textAlign = 'center';
        sctx.textBaseline = 'middle';
        sctx.fillText(symbol, size / 2, size / 2 + 4);

        const fctx = foilCanvas.getContext('2d');
        const grad = fctx.createLinearGradient(0, 0, size, size);
        grad.addColorStop(0, '#d4d4d4');
        grad.addColorStop(0.5, '#f2f2f2');
        grad.addColorStop(1, '#b8b8b8');
        fctx.fillStyle = grad;
        fctx.fillRect(0, 0, size, size);
        fctx.fillStyle = '#7a7a7a';
        fctx.font = '13px sans-serif';
        fctx.textAlign = 'center';
        fctx.fillText('GRATTE', size / 2, size / 2 - 6);
        fctx.fillText('ICI', size / 2, size / 2 + 10);

        let isScratching = false;
        let revealed = false;
        let checkPending = false;

        function getPos(evt) {
            const rect = foilCanvas.getBoundingClientRect();
            const clientX = evt.touches ? evt.touches[0].clientX : evt.clientX;
            const clientY = evt.touches ? evt.touches[0].clientY : evt.clientY;
            return {
                x: (clientX - rect.left) * (size / rect.width),
                y: (clientY - rect.top) * (size / rect.height),
            };
        }

        function scratchAt(x, y) {
            fctx.globalCompositeOperation = 'destination-out';
            fctx.beginPath();
            fctx.arc(x, y, BRUSH_RADIUS, 0, Math.PI * 2);
            fctx.fill();
        }

        function reveal() {
            if (revealed) return;
            revealed = true;
            fctx.clearRect(0, 0, size, size);
            wrapper.classList.add('revealed');
            revealedCount += 1;
            checkAllRevealed();
        }

        function checkRevealRatio() {
            if (revealed || checkPending) return;
            checkPending = true;
            requestAnimationFrame(() => {
                checkPending = false;
                const data = fctx.getImageData(0, 0, size, size).data;
                let transparent = 0;
                let sampled = 0;
                for (let i = 3; i < data.length; i += 4 * 8) {
                    sampled += 1;
                    if (data[i] === 0) transparent += 1;
                }
                if (sampled > 0 && transparent / sampled > REVEAL_THRESHOLD) {
                    reveal();
                }
            });
        }

        foilCanvas.addEventListener('mousedown', (e) => {
            isScratching = true;
            const p = getPos(e);
            scratchAt(p.x, p.y);
            checkRevealRatio();
        });
        window.addEventListener('mouseup', () => (isScratching = false));
        foilCanvas.addEventListener('mousemove', (e) => {
            if (!isScratching) return;
            const p = getPos(e);
            scratchAt(p.x, p.y);
            checkRevealRatio();
        });
        foilCanvas.addEventListener(
            'touchstart',
            (e) => {
                isScratching = true;
                const p = getPos(e);
                scratchAt(p.x, p.y);
                checkRevealRatio();
                e.preventDefault();
            },
            { passive: false }
        );
        foilCanvas.addEventListener(
            'touchmove',
            (e) => {
                const p = getPos(e);
                scratchAt(p.x, p.y);
                checkRevealRatio();
                e.preventDefault();
            },
            { passive: false }
        );
        foilCanvas.addEventListener('touchend', () => (isScratching = false));

        return { el: wrapper, reveal };
    }

    function checkAllRevealed() {
        if (revealedCount >= 9) {
            setTimeout(showResult, 300);
        }
    }

    let pendingResult = null;

    function showResult() {
        if (!pendingResult) return;
        resultText.textContent = pendingResult.won
            ? `🎉 ${pendingResult.rewardLabel}`
            : `😢 ${pendingResult.rewardLabel}`;
        resultBanner.classList.remove('hidden');
        revealAllBtn.classList.add('hidden');
    }

    function openScratch(result) {
        pendingResult = result;
        revealedCount = 0;
        cellsRevealFns = [];
        grid.innerHTML = '';
        resultBanner.classList.add('hidden');
        revealAllBtn.classList.remove('hidden');
        scratchTitle.textContent = result.ticketLabel || 'Ticket';

        result.grid.forEach((symbol) => {
            const cell = buildCell(symbol);
            cellsRevealFns.push(cell.reveal);
            grid.appendChild(cell.el);
        });

        showApp();
        showScreen(scratchScreen);
    }

    revealAllBtn.addEventListener('click', () => {
        cellsRevealFns.forEach((fn) => fn());
    });

    resultContinueBtn.addEventListener('click', () => {
        post('closeMenu');
        hideApp();
    });

    storeCloseBtn.addEventListener('click', () => {
        post('closeMenu');
        hideApp();
    });

    scratchCloseBtn.addEventListener('click', () => {
        post('closeMenu');
        hideApp();
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            post('closeMenu');
            hideApp();
        }
    });

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || !data.action) return;

        switch (data.action) {
            case 'openStore':
                openStore(data.tickets);
                break;
            case 'openScratch':
                openScratch(data.result);
                break;
            case 'buyDenied':
                storeError.classList.remove('hidden');
                ticketList.querySelectorAll('button[data-id]').forEach((b) => (b.disabled = false));
                break;
            case 'close':
                hideApp();
                break;
        }
    });
})();
