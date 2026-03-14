**Disclaimer:** The maintainers of this project do not have access to your cloud credentials. This application is strictly a TUI and will never intentionally leak access keys, generate unauthorized invoices, or exploit cloud platforms. You, the user, are solely responsible for securing your API keys and managing the financial risks associated with the cloud platforms you connect to.

Below is public information regarding how our supported NeoCloud platforms structure their billing and the financial risks associated with compromised credentials.

---

## Cloud Platform Billing Models

Depending on which backend you connect this TUI to, the billing systems generally operate under the following models:

* **Modal (modal.com):** Primarily utilizes a **postpaid**, pay-as-you-go model. Users are typically invoiced at the end of a billing cycle for the compute resources consumed.
* **SimplePod (simplepod.ai):** Operates on a **prepaid** balance system. Users must deposit funds into their account, and hourly usage is deducted from this balance.
* **Verda (verda.com):** Uses a strictly **prepaid** credit system for on-demand instances. Resources are discontinued or suspended if the account balance reaches zero.
* **Nebius AI (nebius.com):** Uses a **hybrid** model. Standard pay-as-you-go usage is postpaid (invoiced the following month for the previous month's usage), while long-term usage commitments are generally prepaid.

* **Hugging Face (huggingface.co):** Used exclusively in this project as a model registry to download model weights. We need a key, because some models require you to accept license before download. Because we do not use Hugging Face for compute, there are no compute billing risks associated with our usage, provided you supply a strictly Read-Only HF token.

---

## Evaluating the Risk of Leaked Credentials

When cloud access keys are exposed (e.g., accidentally committing them to a public repository), it frequently leads to a "Denial of Wallet" attack. Automated bots scan for leaked keys and immediately hijack the account to spin up expensive, high-tier GPU instances—often to mine cryptocurrency. 

The billing structure heavily dictates how this financial risk unfolds:

* **Postpaid Risk:** Platforms that invoice at the end of the month carry the highest risk for massive, unexpected debt. Because there is no hard cap stopping the deployment of resources, an attacker can rack up thousands of dollars in compute charges before the billing cycle ends and the legitimate user realizes what has happened.
* **Prepaid Risk:** On the surface, the immediate risk is limited to whatever funds are currently sitting in the account balance. However, the danger increases significantly if **auto-top-up** is enabled. If a compromised prepaid account is configured to automatically charge a credit card whenever the balance drops below a certain threshold, attackers can trigger a loop of repeated charges, resulting in a similarly massive financial drain.

---

## Best Practices for Users

To prevent unauthorized resource consumption, we strongly advise you to:
1. **Never hardcode your keys:** Always use environment variables (`.env` files added to your `.gitignore`) or secure secret managers to pass credentials to this GUI.
2. **Set strict billing alerts:** Configure budget alerts directly in your Modal, SimplePod, Verda, or Nebius dashboards.
3. **Manage Auto-Top-Up carefully:** If using a prepaid platform, disable auto-top-up features unless strictly necessary.
  - **HINT:** We are using virtual "prepaid" credit card for auto-top-up which prevents large $$$ runaways.

## Reporting a Vulnerability

If you discover a security vulnerability within the TUI codebase itself (e.g., how the app stores or handles keys locally), please do not open a public issue. Instead, report it directly to the maintainers.

