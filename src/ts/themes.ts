export interface ThemeSettings {
	preferredLight: string;
	preferredDark: string;
}

const STORAGE_KEY = 'startpage_theme_preferences_v2';

const defaultSettings: ThemeSettings = {
	preferredLight: 'noctalia',
	preferredDark: 'noctalia'
};

export function getThemeSettings(): ThemeSettings {
	const savedV2 = localStorage.getItem(STORAGE_KEY);
	if (savedV2) {
		try {
			return JSON.parse(savedV2) as ThemeSettings;
		} catch {
			return defaultSettings;
		}
	}

	const legacy = localStorage.getItem('startpage_theme_preferences');
	if (legacy) {
		try {
			const parsed = JSON.parse(legacy) as ThemeSettings;
			if (parsed.preferredDark === 'noctalia' || parsed.preferredLight === 'noctalia') {
				return parsed;
			}
		} catch {
			// fall through
		}
	}

	return defaultSettings;
}

export function saveThemeSettings(settings: ThemeSettings): void {
	localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
	localStorage.setItem('startpage_theme_preferences', JSON.stringify(settings));
	applyCurrentTheme();
}

export function ensureNoctaliaStylesheet(): void {
	let link = document.getElementById('noctalia-theme-css') as HTMLLinkElement | null;
	if (!link) {
		link = document.createElement('link');
		link.id = 'noctalia-theme-css';
		link.rel = 'stylesheet';
		document.head.appendChild(link);
	} else if (link.parentNode === document.head && document.head.lastElementChild !== link) {
		document.head.appendChild(link);
	}
	const ts = Date.now();
	link.href = `./noctalia.css?t=${ts}`;
}

export function applyCurrentTheme(): void {
	const settings = getThemeSettings();
	const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
	const themeToApply = systemPrefersDark ? settings.preferredDark : settings.preferredLight;
	document.documentElement.setAttribute('data-theme', themeToApply);
	if (themeToApply.startsWith('noctalia')) {
		ensureNoctaliaStylesheet();
	}
}

export function initThemes(): void {
	ensureNoctaliaStylesheet();
	applyCurrentTheme();
	window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
		applyCurrentTheme();
	});
}
