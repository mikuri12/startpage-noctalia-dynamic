export interface ThemeSettings {
	preferredLight: string;
	preferredDark: string;
}

const STORAGE_KEY = 'startpage_theme_preferences';

const defaultSettings: ThemeSettings = {
	preferredLight: 'noctalia',
	preferredDark: 'noctalia'
};

export function getThemeSettings(): ThemeSettings {
	const saved = localStorage.getItem(STORAGE_KEY);
	if (!saved) return defaultSettings;
	try {
		const parsed = JSON.parse(saved) as ThemeSettings;
		// Sanitize legacy default values if present
		if (parsed.preferredDark === 'dracula-dark') parsed.preferredDark = 'noctalia';
		if (parsed.preferredLight === 'latte') parsed.preferredLight = 'noctalia';
		return parsed;
	} catch {
		return defaultSettings;
	}
}

export function saveThemeSettings(settings: ThemeSettings): void {
	localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
	applyCurrentTheme();
}

export function reloadNoctaliaCSS(): void {
	const link = document.getElementById('noctalia-theme-css') as HTMLLinkElement | null;
	if (link) {
		const baseHref = link.href.split('?')[0];
		link.href = `${baseHref}?ts=${Date.now()}`;
	}
}

export function applyCurrentTheme(): void {
	const settings = getThemeSettings();
	const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
	const themeToApply = systemPrefersDark ? settings.preferredDark : settings.preferredLight;
	document.documentElement.setAttribute('data-theme', themeToApply);
}

export function initThemes(): void {
	applyCurrentTheme();
	window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
		applyCurrentTheme();
	});

	// Optional live reload for local development when noctalia updates
	if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
		setInterval(async () => {
			const currentTheme = document.documentElement.getAttribute('data-theme');
			if (currentTheme?.startsWith('noctalia')) {
				try {
					const res = await fetch(`./noctalia.css?check=${Date.now()}`, { method: 'HEAD', cache: 'no-store' });
					if (res.ok) {
						// CSS exists and is active
					}
				} catch {
					// Ignore network errors in polling
				}
			}
		}, 3000);
	}
}
