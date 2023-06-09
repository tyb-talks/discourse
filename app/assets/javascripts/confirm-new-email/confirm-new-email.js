import { getWebauthnCredential } from "discourse/lib/webauthn";

const security = document.getElementById("submit-security-key");
if (security) {
  security.onclick = function (e) {
    e.preventDefault();
    getWebauthnCredential(
      document.getElementById("security-key-challenge").value,
      document
        .getElementById("security-key-allowed-credential-ids")
        .value.split(","),
      (credentialData) => {
        document.getElementById("security-key-credential").value =
          JSON.stringify(credentialData);

        e.target.closest("form").submit();
      },
      (errorMessage) => {
        document.getElementById(
          "security-key-error"
        ).innerHTML = `<div class="alert alert-error"></div>`;
        document.querySelector("#security-key-error .alert").innerText =
          errorMessage;
      }
    );
  };
}
