const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'studio';
const $ = (id) => document.getElementById(id);

let presets = null;
let state = null;

// Lua puede mandar tablas vacías como {} en vez de []
const arr = (v) => (Array.isArray(v) ? v : Object.values(v || {}));

async function post(name, data = {}) {
  try {
    const res = await fetch(`https://${RES}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    const next = await res.json();
    if (next && typeof next === 'object') render(next);
  } catch (err) {
    console.error(`[studio] ${name}`, err);
  }
}

// ---------- helpers de formulario ----------

// No pisar el control que el usuario está tocando
function setValue(id, value) {
  const el = $(id);
  if (!el || el === document.activeElement || value === undefined || value === null) return;
  if (el.type === 'checkbox') el.checked = !!value;
  else el.value = value;
  const out = $(`${id}-out`);
  if (out) out.textContent = typeof value === 'number' ? Number(value).toFixed(value % 1 ? 2 : 0) : value;
}

function fillSelect(id, items) {
  const el = $(id);
  el.innerHTML = '';
  for (const { value, label } of items) {
    const opt = document.createElement('option');
    opt.value = value;
    opt.textContent = label;
    el.appendChild(opt);
  }
}

function li(html) {
  const el = document.createElement('li');
  el.innerHTML = html;
  return el;
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

// ---------- render ----------

function render(next) {
  state = next;
  const { freecam, cine, visual, world } = state;

  // Cámara
  $('fc-toggle').textContent = freecam.active ? 'Desactivar freecam' : 'Activar freecam';
  $('fc-toggle').classList.toggle('primary', !freecam.active);
  setValue('fc-fov', freecam.fov);
  setValue('fc-speed', freecam.speed);
  setValue('fc-roll', freecam.roll);
  setValue('dof-enabled', freecam.dof.enabled);
  setValue('dof-near', freecam.dof.near);
  setValue('dof-far', freecam.dof.far);
  setValue('dof-strength', freecam.dof.strength);

  // Cinemática
  const kfList = $('kf-list');
  kfList.innerHTML = '';
  const keyframes = arr(cine.keyframes);
  if (!keyframes.length) kfList.appendChild(li('Sin keyframes. Activa la freecam y pulsa K.')).classList.add('empty');
  keyframes.forEach((kf, i) => {
    const idx = i + 1;
    const last = idx === keyframes.length;
    const row = li(`
      <span class="grow">#${idx} <span class="meta">FOV ${kf.fov.toFixed(1)}</span></span>
      ${last ? '<span class="meta">fin</span>' : `<input type="number" min="0.1" max="600" step="0.1" value="${kf.duration}" title="Segundos hasta el siguiente">`}
      <button class="small" data-kf="goto" title="Ir">Ir</button>
      <button class="small" data-kf="update" title="Reemplazar con la cámara actual">↻</button>
      <button class="small danger" data-kf="remove" title="Borrar">✕</button>`);
    row.querySelectorAll('[data-kf]').forEach((b) =>
      b.addEventListener('click', () => post(`cine:${b.dataset.kf}`, { index: idx })));
    const dur = row.querySelector('input');
    if (dur) dur.addEventListener('change', () => post('cine:duration', { index: idx, duration: Number(dur.value) }));
    kfList.appendChild(row);
  });

  setValue('cine-ease', cine.settings.ease);
  setValue('cine-countdown', cine.settings.countdown);
  setValue('cine-letterbox', cine.settings.letterbox);
  setValue('cine-loop', cine.settings.loop);
  setValue('cine-record', cine.settings.record);
  $('cine-play').disabled = cine.playing;

  const sceneList = $('scene-list');
  sceneList.innerHTML = '';
  const scenes = arr(state.scenes);
  if (!scenes.length) sceneList.appendChild(li('No hay escenas guardadas.')).classList.add('empty');
  scenes.forEach((s) => {
    const row = li(`
      <span class="grow">${escapeHtml(s.name)} <span class="meta">${s.keyframes} kf · ${escapeHtml(s.author || '?')}</span></span>
      <button class="small" data-s="load">Cargar</button>
      <button class="small danger" data-s="delete">✕</button>`);
    row.querySelector('[data-s=load]').addEventListener('click', () => post('scene:load', { name: s.name }));
    // Doble clic de confirmación (confirm() no está disponible en NUI)
    const del = row.querySelector('[data-s=delete]');
    del.addEventListener('click', () => {
      if (del.dataset.armed) return post('scene:delete', { name: s.name });
      del.dataset.armed = '1';
      del.textContent = '¿Seguro?';
      setTimeout(() => { delete del.dataset.armed; del.textContent = '✕'; }, 2500);
    });
    sceneList.appendChild(row);
  });

  // Foto
  for (const key of ['hideHud', 'letterbox', 'grid', 'hidePlayer', 'filter', 'filterStrength', 'timeScale']) {
    setValue(`v-${key}`, visual[key]);
  }

  // Mundo
  if (world) {
    for (const key of ['weather', 'hour', 'minute', 'freezeTime', 'blackout', 'density', 'wind']) {
      setValue(`w-${key}`, world[key]);
    }
  }

  // Actores
  const actors = arr(state.actors);
  const target = $('a-target');
  const prevTarget = target.value;
  fillSelect('a-target', [
    { value: 0, label: 'Mi personaje' },
    ...actors.map((a, i) => ({ value: i + 1, label: `#${i + 1} ${a.model}` })).filter((_, i) => actors[i].kind === 'ped'),
  ]);
  if ([...target.options].some((o) => o.value === prevTarget)) target.value = prevTarget;

  const actorList = $('actor-list');
  actorList.innerHTML = '';
  if (!actors.length) actorList.appendChild(li('Nada colocado todavía.')).classList.add('empty');
  const kindLabel = { ped: 'Personaje', vehicle: 'Vehículo', prop: 'Prop' };
  actors.forEach((a, i) => {
    const idx = i + 1;
    const row = li(`
      <span class="grow">#${idx} ${escapeHtml(a.model)} <span class="meta">${kindLabel[a.kind]}${a.anim ? ' · ' + escapeHtml(a.anim) : ''}</span></span>
      <button class="small" data-a="freeze">${a.frozen ? 'Soltar' : 'Fijar'}</button>
      <button class="small danger" data-a="delete">✕</button>`);
    row.querySelector('[data-a=freeze]').addEventListener('click', () => post('actor:freeze', { index: idx }));
    row.querySelector('[data-a=delete]').addEventListener('click', () => post('actor:delete', { index: idx }));
    actorList.appendChild(row);
  });
}

function applyPresets(p) {
  presets = p;
  fillSelect('v-filter', arr(p.filters).map((f) => ({ value: f.id, label: f.label })));
  fillSelect('w-weather', arr(p.weathers).map((w) => ({ value: w.id, label: w.label })));
  fillSelect('a-anim', arr(p.animations).map((label, i) => ({ value: i + 1, label })));
  $('fc-fov').min = p.freecam.minFov;
  $('fc-fov').max = p.freecam.maxFov;
  $('fc-speed').min = p.freecam.minSpeed;
  $('fc-speed').max = p.freecam.maxSpeed;
  if (!$('kf-duration').value) $('kf-duration').value = p.defaultDuration;
  updateModelList();
}

function updateModelList() {
  if (!presets) return;
  const list = $('a-models');
  list.innerHTML = '';
  for (const m of arr(presets.models[$('a-kind').value])) {
    const opt = document.createElement('option');
    opt.value = m;
    list.appendChild(opt);
  }
}

// ---------- eventos del panel ----------

document.querySelectorAll('.tab').forEach((tab) =>
  tab.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach((t) => t.classList.toggle('active', t === tab));
    document.querySelectorAll('.page').forEach((p) => p.classList.toggle('active', p.id === `tab-${tab.dataset.tab}`));
  }));

// Botones simples
document.querySelectorAll('[data-action]').forEach((b) =>
  b.addEventListener('click', () => post(b.dataset.action)));

// Cámara
$('fc-toggle').addEventListener('click', () => post('freecam:toggle'));
const liveOut = (id) => $(`${id}-out`) && ($(`${id}-out`).textContent = Number($(id).value).toFixed(2));
['fc-fov', 'fc-speed', 'fc-roll'].forEach((id) =>
  $(id).addEventListener('input', () => {
    liveOut(id);
    post('freecam:set', { [id.slice(3)]: Number($(id).value) });
  }));

const sendDof = () => post('freecam:set', {
  dof: {
    enabled: $('dof-enabled').checked,
    near: Number($('dof-near').value),
    far: Number($('dof-far').value),
    strength: Number($('dof-strength').value),
  },
});
$('dof-enabled').addEventListener('change', sendDof);
['dof-near', 'dof-far', 'dof-strength'].forEach((id) =>
  $(id).addEventListener('input', () => { liveOut(id); sendDof(); }));

// Cinemática
$('kf-add').addEventListener('click', () => post('cine:add', { duration: Number($('kf-duration').value) }));
$('cine-play').addEventListener('click', () => post('cine:play'));
$('cine-stop').addEventListener('click', () => post('cine:stop'));
$('cine-ease').addEventListener('change', () => post('cine:settings', { ease: $('cine-ease').value }));
$('cine-countdown').addEventListener('change', () => post('cine:settings', { countdown: Number($('cine-countdown').value) }));
['letterbox', 'loop', 'record'].forEach((key) =>
  $(`cine-${key}`).addEventListener('change', () => post('cine:settings', { [key]: $(`cine-${key}`).checked })));
$('scene-save').addEventListener('click', () => {
  const name = $('scene-name').value.trim();
  if (name) post('scene:save', { name });
});

// Foto
['hideHud', 'letterbox', 'grid', 'hidePlayer'].forEach((key) =>
  $(`v-${key}`).addEventListener('change', () => post('visual:set', { [key]: $(`v-${key}`).checked })));
$('v-filter').addEventListener('change', () => post('visual:set', { filter: $('v-filter').value }));
['filterStrength', 'timeScale'].forEach((key) =>
  $(`v-${key}`).addEventListener('input', () => {
    liveOut(`v-${key}`);
    post('visual:set', { [key]: Number($(`v-${key}`).value) });
  }));

// Mundo (va al servidor: se envía al soltar)
$('w-weather').addEventListener('change', () => post('world:set', { weather: $('w-weather').value }));
['hour', 'minute', 'density', 'wind'].forEach((key) => {
  $(`w-${key}`).addEventListener('input', () => liveOut(`w-${key}`));
  $(`w-${key}`).addEventListener('change', () => post('world:set', { [key]: Number($(`w-${key}`).value) }));
});
['freezeTime', 'blackout'].forEach((key) =>
  $(`w-${key}`).addEventListener('change', () => post('world:set', { [key]: $(`w-${key}`).checked })));

// Actores
$('a-kind').addEventListener('change', updateModelList);
$('a-spawn').addEventListener('click', () => {
  const model = $('a-model').value.trim();
  if (model) post('actor:spawn', { kind: $('a-kind').value, model });
});
$('a-play').addEventListener('click', () =>
  post('actor:anim', { target: Number($('a-target').value), anim: Number($('a-anim').value) }));
$('a-stop').addEventListener('click', () => post('actor:stopAnim', { target: Number($('a-target').value) }));

// Cerrar con Esc o F5
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' || e.key === 'F5') {
    e.preventDefault();
    post('close');
  }
});

// ---------- mensajes desde Lua ----------

window.addEventListener('message', ({ data }) => {
  switch (data.action) {
    case 'open':
      applyPresets(data.presets);
      render(data.state);
      $('panel').classList.remove('hidden');
      break;
    case 'close':
      $('panel').classList.add('hidden');
      break;
    case 'state':
      render(data.state);
      break;
    case 'hud':
      $('hud').classList.toggle('hidden', !data.visible);
      if (data.visible) {
        $('hud-speed').textContent = data.speed.toFixed(1);
        $('hud-fov').textContent = data.fov.toFixed(1);
        $('hud-roll').textContent = data.roll.toFixed(1);
      }
      break;
    case 'countdown':
      $('hud').classList.add('hidden');
      $('countdown').textContent = data.value > 0 ? data.value : '';
      $('countdown').classList.toggle('hidden', data.value <= 0);
      break;
  }
});
