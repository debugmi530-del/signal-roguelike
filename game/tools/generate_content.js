#!/usr/bin/env node
// Generates the SIGNAL card/station/enemy/boss resource pool as .tres files.
// Run with: node game/tools/generate_content.js
// Re-run any time to regenerate the whole pool (overwrites existing files).

const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const CARDS_DIR = path.join(ROOT, "resources", "cards");
const STATIONS_DIR = path.join(ROOT, "resources", "stations");
const ENEMIES_DIR = path.join(ROOT, "resources", "enemies");
const BOSSES_DIR = path.join(ROOT, "resources", "bosses");

for (const dir of [CARDS_DIR, STATIONS_DIR, ENEMIES_DIR, BOSSES_DIR]) {
  fs.mkdirSync(dir, { recursive: true });
  for (const f of fs.readdirSync(dir)) {
    if (f.endsWith(".tres")) fs.unlinkSync(path.join(dir, f));
  }
}

const STAT = {
  DAMAGE: 0,
  FIRE_RATE: 1,
  PROJECTILE_COUNT: 2,
  PROJECTILE_SPEED: 3,
  MAX_HP: 4,
  REGEN: 5,
  MOVE_SPEED: 6,
  LUCK: 7,
  PIERCE: 8,
  KNOCKBACK: 9,
};

const RARITY = {
  COMMON: 0,
  UNCOMMON: 1,
  RARE: 2,
  EPIC: 3,
  LEGENDARY: 4,
  MYTHIC: 5,
  ARCHON: 6,
};

function writeCard({ fileName, module, id, displayName, flavor, rarity, modifiers, isSacrifice, sacrificeModifiers }) {
  let loadStep = 2;
  const lines = [];
  const modBlocks = [];
  const modRefs = [];
  const sacBlocks = [];
  const sacRefs = [];

  modifiers.forEach((m, i) => {
    const subId = `Mod${i}`;
    modBlocks.push(`[sub_resource type="Resource" id="${subId}"]\nscript = ExtResource("2")\nstat = ${m.stat}\nvalue = ${m.value}\n`);
    modRefs.push(`SubResource("${subId}")`);
    loadStep++;
  });
  (sacrificeModifiers || []).forEach((m, i) => {
    const subId = `Sac${i}`;
    sacBlocks.push(`[sub_resource type="Resource" id="${subId}"]\nscript = ExtResource("2")\nstat = ${m.stat}\nvalue = ${m.value}\n`);
    sacRefs.push(`SubResource("${subId}")`);
    loadStep++;
  });

  const header = `[gd_resource type="Resource" script_class="CardItem" load_steps=${loadStep} format=3]\n\n` +
    `[ext_resource type="Script" path="res://autoload/CardItem.gd" id="1"]\n` +
    `[ext_resource type="Script" path="res://autoload/CardModifier.gd" id="2"]\n\n`;

  const body = modBlocks.join("\n") + (modBlocks.length ? "\n" : "") + sacBlocks.join("\n") + (sacBlocks.length ? "\n" : "") +
    `[resource]\n` +
    `script = ExtResource("1")\n` +
    `module = "${module}"\n` +
    `id = "${id}"\n` +
    `display_name = "${displayName}"\n` +
    `flavor_text = "${flavor}"\n` +
    `rarity = ${rarity}\n` +
    `modifiers = Array[ExtResource("2")]([${modRefs.join(", ")}])\n` +
    `is_sacrifice = ${isSacrifice ? "true" : "false"}\n` +
    `sacrifice_modifiers = Array[ExtResource("2")]([${sacRefs.join(", ")}])\n`;

  fs.writeFileSync(path.join(CARDS_DIR, fileName), header + body);
}

let counter = 0;
function nextId(prefix) {
  counter++;
  return `${prefix}_${counter}`;
}

// ---- 14 base modules (~200 cards) ----
const baseModules = [
  { key: "damage", label: "Усиление сигнала", stat: STAT.DAMAGE, unit: "урона", base: 3, flavor: "Громче. Резче. Больнее." },
  { key: "fire_rate", label: "Учащение импульса", stat: STAT.FIRE_RATE, unit: "к перезарядке", base: 0.3, flavor: "Помехи идут чаще." },
  { key: "projectile_count", label: "Раздвоение волны", stat: STAT.PROJECTILE_COUNT, unit: "снаряду", base: 1, flavor: "Один сигнал — уже не один." },
  { key: "projectile_speed", label: "Ускорение волны", stat: STAT.PROJECTILE_SPEED, unit: "к скорости снаряда", base: 60, flavor: "Быстрее эфира." },
  { key: "trajectory", label: "Искривление траектории", stat: STAT.KNOCKBACK, unit: "к отбрасыванию", base: 20, flavor: "Волна бьёт вбок." },
  { key: "on_hit", label: "Пробивающий эффект", stat: STAT.PIERCE, unit: "к пробитию", base: 1, flavor: "Проходит сквозь помехи." },
  { key: "survival", label: "Стабильность приёма", stat: STAT.MAX_HP, unit: "к макс. HP", base: 1, flavor: "Сигнал держится дольше." },
  { key: "regen", label: "Самовосстановление", stat: STAT.REGEN, unit: "к регенерации", base: 0.2, flavor: "Эхо затягивает раны." },
  { key: "mobility", label: "Скорость дрейфа", stat: STAT.MOVE_SPEED, unit: "к скорости передвижения", base: 20, flavor: "Быстрее ускользает." },
  { key: "economy", label: "Удачная частота", stat: STAT.LUCK, unit: "к удаче", base: 3, flavor: "Шанс на лучшую находку." },
  { key: "aura", label: "Аура помех", stat: STAT.REGEN, unit: "к регенерации (аура)", base: 0.15, flavor: "Поле вокруг эха лечит." },
  { key: "active", label: "Активный всплеск", stat: STAT.FIRE_RATE, unit: "к перезарядке (всплеск)", base: 0.4, flavor: "Импульс по требованию." },
  { key: "station_synergy", label: "Резонанс станции", stat: STAT.DAMAGE, unit: "урона (резонанс)", base: 2, flavor: "Созвучно текущей частоте." },
  { key: "unique", label: "Архонтовый отголосок", stat: STAT.DAMAGE, unit: "урона (уникальный эффект)", base: 5, flavor: "Нечто древнее в эфире." },
];

const rarityOrder = [
  RARITY.COMMON, RARITY.COMMON, RARITY.COMMON,
  RARITY.UNCOMMON, RARITY.UNCOMMON,
  RARITY.RARE, RARITY.RARE,
  RARITY.EPIC,
  RARITY.LEGENDARY,
  RARITY.MYTHIC,
  RARITY.ARCHON,
];
const rarityMult = {
  [RARITY.COMMON]: 1,
  [RARITY.UNCOMMON]: 1.6,
  [RARITY.RARE]: 2.4,
  [RARITY.EPIC]: 3.6,
  [RARITY.LEGENDARY]: 5.2,
  [RARITY.MYTHIC]: 7.5,
  [RARITY.ARCHON]: 11,
};
const rarityWord = {
  [RARITY.COMMON]: "I",
  [RARITY.UNCOMMON]: "II",
  [RARITY.RARE]: "III",
  [RARITY.EPIC]: "IV",
  [RARITY.LEGENDARY]: "V",
  [RARITY.MYTHIC]: "VI",
  [RARITY.ARCHON]: "VII",
};

let cardFileIndex = 0;
baseModules.forEach((mod) => {
  rarityOrder.forEach((rarity, i) => {
    cardFileIndex++;
    const value = Math.round(mod.base * rarityMult[rarity] * 10) / 10;
    const id = nextId(mod.key);
    const isStarter = mod.key.match(/damage|fire_rate|projectile_count|survival|mobility/) && rarity === RARITY.COMMON && i === 0;
    writeCard({
      fileName: `${String(cardFileIndex).padStart(3, "0")}_${id}.tres`,
      module: mod.key,
      id: isStarter ? `starter_${mod.key}` : id,
      displayName: `${mod.label} ${rarityWord[rarity]}`,
      flavor: mod.flavor,
      rarity,
      modifiers: [{ stat: mod.stat, value }],
      isSacrifice: false,
    });
  });
});

// A few starter basics beyond the auto-marked ones, to guarantee exactly 10
// starter cards are unlocked from the very first run.
const starterExtras = [
  { key: "projectile_speed", stat: STAT.PROJECTILE_SPEED, value: 60, label: "Ускорение волны I" },
  { key: "regen", stat: STAT.REGEN, value: 0.2, label: "Самовосстановление I" },
  { key: "economy", stat: STAT.LUCK, value: 3, label: "Удачная частота I" },
  { key: "on_hit", stat: STAT.PIERCE, value: 1, label: "Пробивающий эффект I" },
  { key: "trajectory", stat: STAT.KNOCKBACK, value: 20, label: "Искривление траектории I" },
];
starterExtras.forEach((extra) => {
  cardFileIndex++;
  writeCard({
    fileName: `${String(cardFileIndex).padStart(3, "0")}_starter_${extra.key}.tres`,
    module: extra.key,
    id: `starter_${extra.key}`,
    displayName: extra.label,
    flavor: "Базовая частота, доступна с самого начала.",
    rarity: RARITY.COMMON,
    modifiers: [{ stat: extra.stat, value: extra.value }],
    isSacrifice: false,
  });
});

// ---- 10 sacrifice sub-groups (~100 cards) mirroring the same stat categories ----
const sacrificeGroups = [
  { key: "sac_damage", label: "Жертва: урон", gain: STAT.DAMAGE, gainUnit: "к урону", cost: STAT.MAX_HP, costUnit: "к макс. HP" },
  { key: "sac_fire_rate", label: "Жертва: перезарядка", gain: STAT.FIRE_RATE, gainUnit: "к перезарядке", cost: STAT.MAX_HP, costUnit: "к макс. HP" },
  { key: "sac_projectile", label: "Жертва: снаряды", gain: STAT.PROJECTILE_COUNT, gainUnit: "к снарядам", cost: STAT.MOVE_SPEED, costUnit: "к скорости передвижения" },
  { key: "sac_projectile_speed", label: "Жертва: скорость волны", gain: STAT.PROJECTILE_SPEED, gainUnit: "к скорости снаряда", cost: STAT.FIRE_RATE, costUnit: "к перезарядке" },
  { key: "sac_trajectory", label: "Жертва: траектория", gain: STAT.PIERCE, gainUnit: "к пробитию", cost: STAT.DAMAGE, costUnit: "к урону" },
  { key: "sac_survival", label: "Жертва: живучесть", gain: STAT.MAX_HP, gainUnit: "к макс. HP", cost: STAT.MOVE_SPEED, costUnit: "к скорости передвижения" },
  { key: "sac_mobility", label: "Жертва: манёвренность", gain: STAT.MOVE_SPEED, gainUnit: "к скорости передвижения", cost: STAT.MAX_HP, costUnit: "к макс. HP" },
  { key: "sac_luck", label: "Жертва: удача", gain: STAT.LUCK, gainUnit: "к удаче", cost: STAT.DAMAGE, costUnit: "к урону" },
  { key: "sac_active", label: "Жертва: импульс", gain: STAT.FIRE_RATE, gainUnit: "к перезарядке", cost: STAT.PROJECTILE_SPEED, costUnit: "к скорости снаряда" },
  { key: "sac_unique", label: "Жертва: отголосок", gain: STAT.DAMAGE, gainUnit: "к урону (уникальный)", cost: STAT.REGEN, costUnit: "к регенерации" },
];

sacrificeGroups.forEach((group) => {
  rarityOrder.forEach((rarity, i) => {
    cardFileIndex++;
    const gainValue = Math.round((2 + rarityMult[rarity] * 1.4) * 10) / 10;
    const costValue = Math.round((1 + rarityMult[rarity] * 0.7) * 10) / 10;
    const id = nextId(group.key);
    writeCard({
      fileName: `${String(cardFileIndex).padStart(3, "0")}_${id}.tres`,
      module: group.key,
      id,
      displayName: `${group.label} ${rarityWord[rarity]}`,
      flavor: "Ничто не даётся бесплатно в эфире.",
      rarity,
      modifiers: [{ stat: group.gain, value: gainValue }],
      isSacrifice: true,
      sacrificeModifiers: [{ stat: group.cost, value: -costValue }],
    });
  });
});

console.log(`Cards generated: ${cardFileIndex}`);

// ---- 8 station themes ----
const stations = [
  { id: "kids_show", name: "Детская передача", bg: "0.55,0.75,0.95", wall: "0.75,0.85,0.98", accent: "1.0,0.85,0.3", enemies: ["static_puppet", "balloon_drone"] },
  { id: "military", name: "Военные позывные", bg: "0.15,0.18,0.12", wall: "0.28,0.3,0.22", accent: "0.7,0.85,0.3", enemies: ["scrambler_drone", "sentry_burst"] },
  { id: "talk_show", name: "Ночное ток-шоу", bg: "0.12,0.08,0.16", wall: "0.24,0.16,0.28", accent: "0.85,0.4,0.9", enemies: ["mic_feedback", "sentry_burst"] },
  { id: "ad_break", name: "Реклама", bg: "0.85,0.75,0.1", wall: "0.95,0.88,0.3", accent: "1.0,0.2,0.3", enemies: ["static_puppet", "balloon_drone"] },
  { id: "weather", name: "Погодная станция", bg: "0.1,0.25,0.35", wall: "0.2,0.4,0.5", accent: "0.6,0.9,1.0", enemies: ["storm_wisp", "scrambler_drone"] },
  { id: "emergency", name: "Аварийное вещание", bg: "0.3,0.05,0.05", wall: "0.5,0.1,0.1", accent: "1.0,0.7,0.1", enemies: ["sentry_burst", "storm_wisp"] },
  { id: "religious", name: "Религиозная трансляция", bg: "0.2,0.16,0.05", wall: "0.4,0.32,0.1", accent: "1.0,0.95,0.6", enemies: ["mic_feedback", "static_puppet"] },
  { id: "noir", name: "Детектив-нуар", bg: "0.08,0.08,0.1", wall: "0.18,0.18,0.2", accent: "0.8,0.8,0.85", enemies: ["scrambler_drone", "mic_feedback"] },
];

stations.forEach((s, i) => {
  const enemyArr = s.enemies.map((e) => `&"${e}"`).join(", ");
  const tres = `[gd_resource type="Resource" script_class="StationTheme" load_steps=2 format=3]\n\n` +
    `[ext_resource type="Script" path="res://autoload/StationTheme.gd" id="1"]\n\n` +
    `[resource]\n` +
    `script = ExtResource("1")\n` +
    `id = "${s.id}"\n` +
    `display_name = "${s.name}"\n` +
    `description = "Частота: ${s.name}"\n` +
    `background_color = Color(${s.bg}, 1)\n` +
    `wall_color = Color(${s.wall}, 1)\n` +
    `accent_color = Color(${s.accent}, 1)\n` +
    `favored_enemy_ids = Array[String]([${s.enemies.map((e) => `"${e}"`).join(", ")}])\n`;
  fs.writeFileSync(path.join(STATIONS_DIR, `${String(i + 1).padStart(2, "0")}_${s.id}.tres`), tres);
});
console.log(`Stations generated: ${stations.length}`);

// ---- Enemies ----
const enemies = [
  { id: "static_puppet", name: "Статичная кукла", hp: 12, speed: 90, dmg: 1, radius: 14, color: "0.9,0.4,0.4", ranged: false },
  { id: "balloon_drone", name: "Дрон-шар", hp: 8, speed: 70, dmg: 1, radius: 16, color: "0.9,0.7,0.9", ranged: false },
  { id: "scrambler_drone", name: "Дрон-глушитель", hp: 16, speed: 60, dmg: 1, radius: 15, color: "0.5,0.8,0.5", ranged: true, projSpeed: 260, fireInt: 1.8 },
  { id: "sentry_burst", name: "Импульсная турель", hp: 22, speed: 40, dmg: 2, radius: 18, color: "0.9,0.55,0.2", ranged: true, projSpeed: 300, fireInt: 1.4 },
  { id: "mic_feedback", name: "Обратная связь", hp: 14, speed: 110, dmg: 1, radius: 13, color: "0.8,0.3,0.85", ranged: false },
  { id: "storm_wisp", name: "Грозовой всполох", hp: 10, speed: 130, dmg: 1, radius: 12, color: "0.5,0.75,1.0", ranged: false },
];

enemies.forEach((e, i) => {
  const tres = `[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]\n\n` +
    `[ext_resource type="Script" path="res://autoload/EnemyData.gd" id="1"]\n\n` +
    `[resource]\n` +
    `script = ExtResource("1")\n` +
    `id = "${e.id}"\n` +
    `display_name = "${e.name}"\n` +
    `max_hp = ${e.hp}.0\n` +
    `move_speed = ${e.speed}.0\n` +
    `contact_damage = ${e.dmg}.0\n` +
    `radius = ${e.radius}.0\n` +
    `color = Color(${e.color}, 1)\n` +
    `is_ranged = ${e.ranged ? "true" : "false"}\n` +
    `projectile_speed = ${e.projSpeed || 260}.0\n` +
    `fire_interval = ${e.fireInt || 1.6}\n` +
    `xp_weight = 1.0\n`;
  fs.writeFileSync(path.join(ENEMIES_DIR, `${String(i + 1).padStart(2, "0")}_${e.id}.tres`), tres);
});
console.log(`Enemies generated: ${enemies.length}`);

// ---- Bosses ----
const bosses = [
  { id: "the_announcer", name: "Диктор", hp: 260, speed: 55, dmg: 2, radius: 36, color: "0.9,0.3,0.5", projSpeed: 280, burst: 10, interval: 2.0 },
  { id: "static_king", name: "Король помех", hp: 320, speed: 45, dmg: 2, radius: 40, color: "0.4,0.9,0.6", projSpeed: 320, burst: 14, interval: 1.8 },
  { id: "the_censor", name: "Цензор", hp: 380, speed: 50, dmg: 3, radius: 38, color: "0.85,0.75,0.2", projSpeed: 300, burst: 12, interval: 1.6 },
];

bosses.forEach((b, i) => {
  const tres = `[gd_resource type="Resource" script_class="BossData" load_steps=2 format=3]\n\n` +
    `[ext_resource type="Script" path="res://autoload/BossData.gd" id="1"]\n\n` +
    `[resource]\n` +
    `script = ExtResource("1")\n` +
    `id = "${b.id}"\n` +
    `display_name = "${b.name}"\n` +
    `max_hp = ${b.hp}.0\n` +
    `move_speed = ${b.speed}.0\n` +
    `contact_damage = ${b.dmg}.0\n` +
    `radius = ${b.radius}.0\n` +
    `color = Color(${b.color}, 1)\n` +
    `projectile_speed = ${b.projSpeed}.0\n` +
    `burst_count = ${b.burst}\n` +
    `burst_interval = ${b.interval}\n` +
    `phase_two_hp_ratio = 0.5\n`;
  fs.writeFileSync(path.join(BOSSES_DIR, `${String(i + 1).padStart(2, "0")}_${b.id}.tres`), tres);
});
console.log(`Bosses generated: ${bosses.length}`);
