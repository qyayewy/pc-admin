const end_session_btn = document.getElementById("end-session")

end_session_btn.addEventListener('click', function () {
    const isConfirmed = confirm("Вы действительно хотите завершить сессию?")

    if (isConfirmed) {
        alert("Сессия завршена")
    }
})