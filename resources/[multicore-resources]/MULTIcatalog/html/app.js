// MULTIcatalog page. Shows what the server sends; every order and collection goes back to the server.
(function () {
    'use strict';
    const $ = (id) => document.getElementById(id);
    const root = $('cat');
    let L = {};
    let images = [];
    const resolved = {};      // picture name -> folder index that worked, -1 = none
    let state = null;
    let tab = 'catalog';
    let cat = 'all';
    let busy = false;
    const pick = {};          // amount chosen on each catalog entry
    let basket = [];          // [{ name, amount }] in the order added

    function t(key, ...args) {
        let i = 0;
        const s = L[key] != null ? String(L[key]) : key;
        return s.replace(/%%|%[sd]/g, (m) => (m === '%%' ? '%' : (args[i++] ?? '')));
    }
    function applyLocale() {
        document.querySelectorAll('[data-l]').forEach((el) => { el.textContent = t(el.dataset.l); });
    }
    function esc(s) {
        return String(s == null ? '' : s).replace(/[&<>"']/g, (ch) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
    }
    function num(n) { n = Number(n); return isFinite(n) ? n : 0; }
    function sign() { return (state && state.sign) || '$'; }
    function moneyText(n) { return sign() + num(n).toFixed(2); }
    // game money: $1 with small raised cents
    function moneyHtml(n) {
        n = Math.round(num(n) * 100) / 100;
        const whole = Math.floor(n), cents = Math.round((n - whole) * 100);
        return esc(sign()) + whole + '<span class="mc-cents">' + (cents < 10 ? '0' : '') + cents + '</span>';
    }

    // ---------- pictures: the inventory's folders in order, then a drawn mark ----------
    function imgHtml(image) {
        if (!image || !images.length || resolved[image] === -1) return '<i class="fallback"></i>';
        const i = resolved[image] !== undefined ? resolved[image] : 0;
        return `<img data-img="${esc(image)}" data-i="${i}" src="${esc(images[i] + image)}" alt="">`;
    }
    function wireImages(box) {
        box.querySelectorAll('img[data-img]').forEach((img) => {
            img.onload = () => { resolved[img.dataset.img] = num(img.dataset.i); };
            img.onerror = () => {
                const name = img.dataset.img, i = num(img.dataset.i) + 1;
                if (i < images.length) { img.dataset.i = i; img.src = images[i] + name; return; }
                resolved[name] = -1;
                const f = document.createElement('i'); f.className = 'fallback';
                if (img.parentNode) img.parentNode.replaceChild(f, img);
            };
        });
    }

    function post(name, data) {
        const res = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'MULTIcatalog';
        return fetch(`https://${res}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        }).then((r) => r.json()).catch(() => ({ ok: false }));
    }
    function say(text, ok) {
        const m = $('msg');
        m.textContent = text || '';
        m.className = 'msg ' + (text ? (ok ? 'ok' : 'bad') : '');
    }
    async function act(action, data) {
        if (busy) return null;
        busy = true;
        const res = await post('action', { action, data });
        busy = false;
        if (res && res.state) { state = res.state; render(); }
        if (res && (res.msg || !res.ok)) say(res.msg, res.ok);
        return res;
    }

    function entry(name) { return (state.catalog || []).find((e) => e.name === name) || null; }
    function limits() { return state.limits || { MaxUnitsPerOrder: 20, MaxLinesPerOrder: 8, MaxPerLine: 10, MaxOpenOrders: 3 }; }
    function units() { return basket.reduce((s, l) => s + l.amount, 0); }

    // ---------- catalog ----------
    function renderCats() {
        const list = ['all'].concat(state.categories || []);
        if (!list.includes(cat)) cat = 'all';
        $('cats').innerHTML = list.map((c) => `<button class="${c === cat ? 'active' : ''}" data-cat="${esc(c)}">${esc(t('cat_' + c))}</button>`).join('');
        $('cats').querySelectorAll('button').forEach((b) => { b.onclick = () => { cat = b.dataset.cat; renderCats(); renderGoods(); }; });
    }

    function renderGoods() {
        const list = (state.catalog || []).filter((e) => cat === 'all' || e.category === cat);
        const box = $('goods');
        if (!list.length) { box.innerHTML = `<div class="empty">${esc(t('ui_empty_cat'))}</div>`; return; }
        box.innerHTML = list.map((e) => `
            <div class="good" data-name="${esc(e.name)}">
                <div class="pic">${imgHtml(e.image)}</div>
                <div class="info">
                    <span class="name">${esc(e.label)}</span>
                    <span class="desc">${esc(e.desc)}</span>
                    <div class="buy">
                        <span class="price mc-money">${moneyHtml(e.price)}<small>${esc(t('ui_each'))}</small></span>
                        <div class="qty"><button data-d="-1">&#8249;</button><span>${pick[e.name] || 1}</span><button data-d="1">&#8250;</button></div>
                        <button class="mc-btn small" data-add="1">${esc(t('ui_add'))}</button>
                    </div>
                </div>
            </div>`).join('');
        wireImages(box);
        box.querySelectorAll('.good').forEach((el) => {
            const name = el.dataset.name;
            el.querySelectorAll('[data-d]').forEach((b) => {
                b.onclick = () => {
                    pick[name] = Math.max(1, Math.min(limits().MaxPerLine, (pick[name] || 1) + Number(b.dataset.d)));
                    el.querySelector('.qty span').textContent = pick[name];
                };
            });
            el.querySelector('[data-add]').onclick = () => addToBasket(name, pick[name] || 1);
        });
    }

    function addToBasket(name, amount) {
        const lim = limits();
        const line = basket.find((l) => l.name === name);
        if (!line && basket.length >= lim.MaxLinesPerOrder) return say(t('err_too_many_lines', lim.MaxLinesPerOrder), false);
        const have = line ? line.amount : 0;
        if (have + amount > lim.MaxPerLine) return say(t('err_too_many_each', lim.MaxPerLine), false);
        if (units() + amount > lim.MaxUnitsPerOrder) return say(t('err_too_many_units', lim.MaxUnitsPerOrder), false);
        if (line) line.amount += amount; else basket.push({ name, amount });
        say('');
        renderBasket();
    }

    function renderBasket() {
        basket = basket.filter((l) => entry(l.name));
        const box = $('lines');
        if (!basket.length) box.innerHTML = `<div class="empty">${esc(t('ui_basket_empty'))}</div>`;
        else {
            box.innerHTML = basket.map((l, i) => {
                const e = entry(l.name);
                return `<div class="line"><span class="n">${l.amount}x</span><span class="what">${esc(e.label)}</span>
                    <span class="mc-money">${moneyHtml(e.price * l.amount)}</span><button class="x" data-i="${i}" title="${esc(t('ui_remove'))}">&#215;</button></div>`;
            }).join('');
            box.querySelectorAll('.x').forEach((b) => { b.onclick = () => { basket.splice(Number(b.dataset.i), 1); renderBasket(); }; });
        }
        const total = basket.reduce((s, l) => s + entry(l.name).price * l.amount, 0);
        $('total').innerHTML = moneyHtml(total);
        $('units').textContent = t('ui_units', units(), limits().MaxUnitsPerOrder);
        $('btnOrder').disabled = !basket.length || !state.canOrder || total > num(state.cash) + 0.001;
    }

    function renderForm() {
        const sel = $('office');
        const keep = sel.value || (state.office && state.office.id) || '';
        sel.innerHTML = (state.offices || []).map((o) => `<option value="${esc(o.id)}">${esc(o.label)}</option>`).join('');
        if ([...sel.options].some((o) => o.value === keep)) sel.value = keep;
        $('away').textContent = state.canOrder ? '' : t('ui_browse_only');
        renderBasket();
    }

    // ---------- orders ----------
    function renderOrders() {
        const list = state.orders || [];
        $('openCount').textContent = state.openCount ? `(${state.openCount})` : '';
        const box = $('orders');
        if (!list.length) { box.innerHTML = `<div class="empty">${esc(t('ui_orders_empty'))}</div>`; return; }
        box.innerHTML = list.map((o) => {
            let side = `<span class="status ${o.status}">${esc(t('ui_status_' + o.status))}</span>`;
            if (o.status === 'transit') side += `<span class="note">${esc(o.eta || '')}</span>`;
            if (o.status === 'arrived') {
                side += o.canCollect ? `<button class="mc-btn primary small" data-collect="${o.id}">${esc(t('ui_collect'))}</button>`
                    : `<span class="note">${esc(t('ui_collect_at', o.officeLabel))}</span>`;
                if (o.partial) side += `<span class="note">${esc(t('ui_partial'))}</span>`;
            }
            return `<div class="order ${o.status === 'collected' ? 'done' : o.status}">
                <div class="top"><span class="no">${esc(t('ui_order_no', o.id))}</span>
                    <span class="meta">${esc(o.officeLabel)}</span>
                    <span class="meta">${esc(t('ui_ordered_on', o.date))}</span>
                    <span class="meta">${esc(t('ui_paid', moneyText(o.total)))}</span></div>
                <div class="items">${(o.lines || []).map((l) => `<span class="it"><span class="pic">${imgHtml(l.image)}</span>${l.amount}x ${esc(l.label)}</span>`).join('')}</div>
                <div class="side">${side}</div>
            </div>`;
        }).join('');
        wireImages(box);
        box.querySelectorAll('[data-collect]').forEach((b) => { b.onclick = () => act('collect', { id: Number(b.dataset.collect) }); });
    }

    // ---------- whole page ----------
    function render() {
        if (!state) return;
        $('where').textContent = state.office ? state.office.label : t('ui_by_post');
        $('delivery').textContent = state.delivery || '';
        $('cash').textContent = t('ui_cash', moneyText(state.cash));
        const take = $('btnTake');
        take.classList.toggle('mc-hidden', !state.offerCatalog);
        if (state.offerCatalog) take.textContent = state.offerCatalog.price > 0 ? t('ui_take_catalog_price', moneyText(state.offerCatalog.price)) : t('ui_take_catalog');
        renderCats();
        renderGoods();
        renderForm();
        renderOrders();
    }

    function showTab(name) {
        tab = name;
        document.querySelectorAll('.mc-tab').forEach((b) => b.classList.toggle('active', b.dataset.tab === name));
        document.querySelectorAll('[data-pane]').forEach((p) => p.classList.toggle('mc-hidden', p.dataset.pane !== name));
        say('');
    }

    // ---------- wiring ----------
    document.querySelectorAll('.mc-tab').forEach((b) => { b.onclick = () => showTab(b.dataset.tab); });
    $('btnOrder').onclick = async () => {
        const res = await act('order', { lines: basket.map((l) => ({ name: l.name, amount: l.amount })), office: $('office').value });
        if (res && res.ok) { basket = []; renderBasket(); }
    };
    $('btnTake').onclick = () => act('take_catalog', {});
    $('close').onclick = () => post('close');
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && !root.classList.contains('mc-hidden')) post('close');
    });

    window.addEventListener('message', (e) => {
        const d = e.data || {};
        if (d.action === 'setup') {
            L = d.L || {};
            images = Array.isArray(d.images) ? d.images : [];
            root.classList.toggle('mc-cyrillic', /^(ru|uk|bg|el|zh|ja|ko|ar|th|vi)$/.test(d.lang));
            applyLocale();
        } else if (d.action === 'open') {
            state = d.state || {};
            render();
            showTab(tab);
            root.classList.remove('mc-hidden');
        } else if (d.action === 'close') {
            root.classList.add('mc-hidden');
            state = null;
        }
    });
})();
