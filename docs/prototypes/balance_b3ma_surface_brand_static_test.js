#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..', '..');
const layoutPath = path.join(root, 'balance_latest_layout.html');
const colorLabPath = path.join(__dirname, 'color_lab.html');
const html = fs.readFileSync(layoutPath, 'utf8');
const colorLab = fs.readFileSync(colorLabPath, 'utf8');

const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((match) => match[1]);
assert.equal(scripts.length, 1, 'the B3M prototype must keep one inspectable inline renderer');
for (const script of scripts) new Function(script);

assert.match(colorLab, /\.spendee-brand-lockup\s*\{[\s\S]*?height:\s*42px;[\s\S]*?gap:\s*10px;[\s\S]*?\}/, 'B3M must retain the 42px / 10px source brand geometry');
assert.match(colorLab, /\.spendee-logo\s*\{[\s\S]*?width:\s*var\(--spendee-logo-icon-size\);[\s\S]*?height:\s*var\(--spendee-logo-icon-size\);[\s\S]*?flex:\s*0 0 auto;[\s\S]*?\}/, 'B3M must remain the source for its logo dimensions');
assert.match(colorLab, /\.spendee-title\s*\{[\s\S]*?font-size:\s*23px;[\s\S]*?\}/, 'B3M must retain its 23px brand name');
assert.match(colorLab, /\.spendee-tagline\s*\{[\s\S]*?font-size:\s*11px;[\s\S]*?\}/, 'B3M must retain its 11px slogan');

const todayStyles = html.match(/function installTodayRedesignStyles\(doc\) \{[\s\S]*?(?=\n\s*function prepareTodayRedesignScreen)/)?.[0];
assert.ok(todayStyles, 'the B3M-A screen style installer must remain inspectable');

assert.match(todayStyles, /\[data-today-redesign-screen="true"\]\s*\{[\s\S]*?background:\s*var\(--gray-50\) !important;[\s\S]*?\}/, 'the B3M-A outer screen must use the B3M gray-50 surface');
assert.match(todayStyles, /\.stage2-redesign-layout\s*\{[\s\S]*?background:\s*var\(--gray-50\);[\s\S]*?\}/, 'the B3M-A visible layout must not cover gray-50 with a white gradient');
assert.match(todayStyles, /\.stage2-redesign-brand\s*\{[\s\S]*?gap:\s*10px;[\s\S]*?height:\s*42px;[\s\S]*?\}/, 'the B3M-A brand lockup must use B3M geometry');
assert.match(todayStyles, /\.stage2-redesign-brand \.spendee-logo\s*\{[\s\S]*?width:\s*var\(--spendee-logo-icon-size\);[\s\S]*?height:\s*var\(--spendee-logo-icon-size\);[\s\S]*?flex:\s*0 0 auto;[\s\S]*?\}/, 'the B3M-A logo must reuse B3M sizing');
assert.match(todayStyles, /\.stage2-redesign-brand \.spendee-title\s*\{[\s\S]*?font-size:\s*23px;[\s\S]*?\}/, 'the B3M-A brand name must use B3M sizing');
assert.match(todayStyles, /\.stage2-redesign-brand \.spendee-tagline\s*\{[\s\S]*?font-size:\s*11px;[\s\S]*?\}/, 'the B3M-A slogan must use B3M sizing');

console.log('B3M-A gray-50 surface and B3M-sized brand static contract passed');
