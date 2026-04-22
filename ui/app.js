const app = document.getElementById('app');
const typeGrid = document.getElementById('typeGrid');
const closeButton = document.getElementById('closeButton');

let allowEscapeClose = true;

function getResourceName() {
    if (typeof GetParentResourceName === 'function') {
        return GetParentResourceName();
    }

    return 'bat_carrypeople';
}

function nui(eventName, payload = {}) {
    fetch(`https://${getResourceName()}/${eventName}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(payload)
    }).catch(() => {});
}

function escapeHtml(value) {
    return String(value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function setOpen(open) {
    document.body.style.display = open ? 'block' : 'none';
    app.dataset.open = open ? 'true' : 'false';
    app.setAttribute('aria-hidden', open ? 'false' : 'true');

    if (!open) {
        typeGrid.innerHTML = '';
    }
}

function closeMenu(sendCallback) {
    setOpen(false);
    if (sendCallback) {
        nui('close');
    }
}

function createTypeCard(type, selectedType, index) {
    const typeId = Number(type.id);
    const enabled = type.enabled === true;
    const isSelected = typeId === Number(selectedType);

    const card = document.createElement('article');
    card.className = `type-card${enabled ? '' : ' is-disabled'}`;
    card.style.animationDelay = `${Math.min(index * 50, 200)}ms`;

    const badge = isSelected ? '<span class="type-card__badge">last used</span>' : '';
    const label = escapeHtml(type.label || `Type ${typeId}`);
    const description = escapeHtml(type.description || '');
    const image = escapeHtml(type.image || '');
    const buttonText = enabled ? 'Select' : 'Disabled';

    card.innerHTML = `
        <div class="type-card__visual">
            <img src="${image}" alt="${label}">
        </div>
        <div class="type-card__content">
            <div class="type-card__meta">
                <h2 class="type-card__title">${label}</h2>
                ${badge}
            </div>
            <p class="type-card__description">${description}</p>
            <button class="type-card__button" type="button" ${enabled ? '' : 'disabled'}>${buttonText}</button>
        </div>
    `;

    const button = card.querySelector('.type-card__button');
    button.addEventListener('click', () => {
        if (!enabled) {
            return;
        }

        closeMenu(false);
        nui('pickType', { typeId });
    });

    return card;
}

function renderTypes(types, selectedType) {
    typeGrid.innerHTML = '';

    if (!Array.isArray(types)) {
        return;
    }

    types.forEach((type, index) => {
        typeGrid.appendChild(createTypeCard(type, selectedType, index));
    });
}

window.addEventListener('message', (event) => {
    const payload = event.data || {};

    if (payload.action === 'open') {
        allowEscapeClose = payload.allowEscapeClose !== false;
        renderTypes(payload.types || [], payload.selectedType);
        setOpen(true);
        return;
    }

    if (payload.action === 'close') {
        closeMenu(false);
    }
});

closeButton.addEventListener('click', () => {
    closeMenu(true);
});

document.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape' || !allowEscapeClose) {
        return;
    }

    closeMenu(true);
});