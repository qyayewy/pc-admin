const loginForm = document.getElementById("login-form");
console.log("Форма входа:", loginForm);

if (loginForm) {
    loginForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        console.log("SUBMIT СРАБОТАЛ");

        const username = document.getElementById("username").value;
        const password = document.getElementById("password").value;

        const errorElement = document.getElementById("login-error");

        errorElement.classList.add("hidden");
        errorElement.textContent = "";

        try {
            const response = await fetch("/login", {
                method: "POST",

                headers: {
                    "Content-Type": "application/json"
                },

                body: JSON.stringify({
                    username: username,
                    password: password
                })
            });

            const data = await response.json();

            if (!response.ok) {
                errorElement.textContent = data.error;
                errorElement.classList.remove("hidden");

                return;
            }

            window.location.href = "/dashboard";

        } catch (error) {
            errorElement.textContent =
                "Не удалось связаться с сервером";

            errorElement.classList.remove("hidden");

            console.error(error);
        }
    });
}

const registerForm = document.getElementById("register-form");

if (registerForm) {
    registerForm.addEventListener("submit", async (event) => {
        event.preventDefault();

        const username = document.getElementById("username").value;
        const email = document.getElementById("email").value;
        const phone = document.getElementById("phone").value;
        const password = document.getElementById("password").value;

        const errorElement =
            document.getElementById("register-error");

        errorElement.classList.add("hidden");
        errorElement.textContent = "";

        try {
            const response = await fetch("/register", {
                method: "POST",

                headers: {
                    "Content-Type": "application/json"
                },

                body: JSON.stringify({
                    username: username,
                    email: email,
                    phone: phone,
                    password: password
                })
            });

            const data = await response.json();

            if (!response.ok) {
                errorElement.textContent = data.error;
                errorElement.classList.remove("hidden");

                return;
            }

            window.location.href = "/login";

        } catch (error) {
            errorElement.textContent =
                "Не удалось связаться с сервером";

            errorElement.classList.remove("hidden");

            console.error(error);
        }
    });
}