import { LightningElement, api } from 'lwc';

export default class FlipBoard extends LightningElement {
    @api label = '';                 // optional heading
    @api status;                     // "in", "out", etc.

    _text = '';
    _previous = '';

    /* ---------- computed classes ---------- */

    get boardClass() {
        // guarantees no "status-undefined"
        return `flipboard status-${this.status ?? 'unknown'}`;
    }

    /** full list of character objects, rebuilt each render */
    get characters() {
        return [...(this._text ?? '')].map((char, idx) => ({ id: idx, char }));
    }

    get statusClass() {
        const s = (this._text || '').toLowerCase();
        if (s.includes('inactive')) return 'status-out';   // put this first
        if (s.includes('active'))   return 'status-in';
        if (s.includes('pause') || s.includes('off')) return 'status-ooo';
        return '';
    }


    /* ---------- public “text” API ---------- */

    @api
    get text() {
        return this._text;
    }
    set text(value) {
        value = typeof value === 'string' ? value : '';
        if (value !== this._previous) {
            this._previous = value;
            this._text = value;
            this.animateFlips();
        }
    }

    /* ---------- flip animation ---------- */

    animateFlips() {
        // wait until DOM has re‑rendered with the new character list
        requestAnimationFrame(() => {
            const flaps = this.template.querySelectorAll('.flap');
            flaps.forEach((flap, index) => {
                flap.classList.remove('flip');
                void flap.offsetWidth;          // force reflow
                setTimeout(() => flap.classList.add('flip'), index * 100);
            });
        });
    }
}
