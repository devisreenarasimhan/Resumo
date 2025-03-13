
const toggle = document.getElementById('theme-toggle');
const body = document.body;
toggle.addEventListener('change', () => {
    if (toggle.checked) {
        body.classList.add('dark-mode');
        body.classList.remove('light-mode');
    } else {
        body.classList.add('light-mode');
        body.classList.remove('dark-mode');
    }
});
