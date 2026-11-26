(() => {
  const SUPABASE_URL = 'https://btokprmspwebfddztnho.supabase.co';
  const SUPABASE_ANON_KEY = 'sb_publishable_p53asdfUCod7Iu6wkh0dVA_Z1yrdhOp';
  const authClient = window.boardieSupabase
    || window.supabase?.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  if (authClient) window.boardieSupabase = authClient;
  const authForm = document.getElementById('authForm');
  const submitButton = document.getElementById('authSubmitBtn');
  const message = document.createElement('p');

  message.className = 'hidden text-sm';
  message.setAttribute('role', 'status');
  message.setAttribute('aria-live', 'polite');
  authForm.insertBefore(message, submitButton);

  function showMessage(text, isError = false) {
    message.textContent = text;
    message.className = isError
      ? 'text-sm text-red-400'
      : 'text-sm text-[#34D399]';
  }

  function updateMarketingAuthLinks(isAuthenticated) {
    const headerAuthActions = document.getElementById('headerAuthActions');
    const headerStudioLink = document.getElementById('headerStudioLink');
    const footerLoginItem = document.getElementById('footerLoginItem');
    const footerSignupItem = document.getElementById('footerSignupItem');
    const footerStudioItem = document.getElementById('footerStudioItem');

    headerAuthActions?.classList.toggle('hidden', isAuthenticated);
    headerStudioLink?.classList.toggle('hidden', !isAuthenticated);
    footerLoginItem?.classList.toggle('hidden', isAuthenticated);
    footerSignupItem?.classList.toggle('hidden', isAuthenticated);
    footerStudioItem?.classList.toggle('hidden', !isAuthenticated);
  }

  if (authClient) {
    authClient.auth.onAuthStateChange((_event, session) => {
      updateMarketingAuthLinks(Boolean(session?.user));
    });

    authClient.auth.getSession().then(({ data, error }) => {
      if (error) throw error;
      updateMarketingAuthLinks(Boolean(data?.session?.user));
    }).catch((error) => {
      console.warn('Could not check marketing page auth session:', error);
    });
  }

  window.handleAuthSubmit = async function (event) {
    event.preventDefault();
    message.className = 'hidden text-sm';

    if (!authClient) {
      showMessage('Authentication is unavailable right now. Please try again later.', true);
      return;
    }

    const email = document.getElementById('authEmail').value.trim();
    const password = document.getElementById('authPassword').value;
    const isSignup = currentAuthMode === 'signup';
    const name = document.getElementById('authName').value.trim();
    const role = document.getElementById('authRole').value;
    const originalButtonText = submitButton.textContent;

    submitButton.disabled = true;
    submitButton.textContent = 'Please wait...';

    try {
      const { data, error } = isSignup
        ? await authClient.auth.signUp({
            email,
            password,
            options: {
              data: { full_name: name, role },
              emailRedirectTo: new URL('studio.html', window.location.href).href
            }
          })
        : await authClient.auth.signInWithPassword({ email, password });

      if (error) throw error;

      if (!data.session || !data.user) {
        showMessage('Account created. Follow the confirmation link sent to your email to finish signing in.');
        return;
      }

      let existing = {};
      try {
        const savedProfile = JSON.parse(localStorage.getItem('boardie_user') || 'null') || {};
        if (savedProfile.authUserId === data.user.id) existing = savedProfile;
      } catch (error) {
        console.warn('Could not read the saved boardie profile:', error);
      }

      try {
        localStorage.setItem('boardie_user', JSON.stringify({
          ...existing,
          authUserId: data.user.id,
          name: isSignup ? name : (existing.name || data.user.user_metadata?.full_name || email.split('@')[0]),
          email: data.user.email || email,
          role: isSignup ? role : (existing.role || data.user.user_metadata?.role || 'creator'),
          loggedInAt: new Date().toISOString()
        }));
      } catch (error) {
        console.warn('Could not save the boardie profile locally:', error);
      }
      window.location.href = 'studio.html';
    } catch (error) {
      showMessage(error?.message || 'Could not authenticate. Please try again.', true);
    } finally {
      submitButton.disabled = false;
      submitButton.textContent = originalButtonText;
    }
  };
})();
