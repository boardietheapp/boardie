(() => {
  const form = document.getElementById('newsletterForm');
  const message = document.getElementById('newsletterMessage');
  const submitButton = form.querySelector('button[type="submit"]');

  message.setAttribute('role', 'status');
  message.setAttribute('aria-live', 'polite');

  function showMessage(text, isError = false) {
    message.textContent = text;
    message.className = isError
      ? 'text-xs text-red-400 pt-1'
      : 'text-xs text-[#34D399] pt-1';
  }

  window.handleNewsletterSubmit = async function (event) {
    event.preventDefault();
    message.className = 'hidden text-xs text-[#34D399] pt-1';

    if (!window.boardieSupabase) {
      showMessage('Signup is temporarily unavailable. Please try again later.', true);
      return;
    }

    const name = document.getElementById('newsletterName').value.trim();
    const email = document.getElementById('newsletterEmail').value.trim().toLowerCase();
    const originalButtonText = submitButton.textContent;

    submitButton.disabled = true;
    submitButton.textContent = 'Subscribing...';

    try {
      const { error } = await window.boardieSupabase
        .from('newsletter_subscribers')
        .insert({ name: name || null, email });

      if (error && error.code !== '23505') throw error;

      showMessage(`Thanks for subscribing! We'll send updates to ${email}.`);
      form.reset();
    } catch (error) {
      console.error('Newsletter subscription failed:', error);
      showMessage('We could not subscribe you right now. Please try again later.', true);
    } finally {
      submitButton.disabled = false;
      submitButton.textContent = originalButtonText;
    }
  };
})();
