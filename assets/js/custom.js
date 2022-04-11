window.onload = () => {
    let commit = document.querySelector("#commit-id > a");
    if (commit != null) {
        let colorCode = commit.innerHTML.trim().substring(1, 7);
        commit.addEventListener('mouseover', function handler() {
            commit.style.color = `#${colorCode}`;
        })
        commit.addEventListener('mouseout', function handler() {
            commit.style.color = '';
        })
    }
}