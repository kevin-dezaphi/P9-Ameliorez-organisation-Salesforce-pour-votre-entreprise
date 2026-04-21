import { createElement } from 'lwc';
import Orders from 'c/orders';
import getSumOrdersByAccount from '@salesforce/apex/MyTeamOrdersController.getSumOrdersByAccount';

// Jest remplace automatiquement l'import Apex par notre mock
jest.mock(
    '@salesforce/apex/MyTeamOrdersController.getSumOrdersByAccount',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

// Utilitaire : laisse le cycle de rendu LWC se terminer
const flushPromises = () => new Promise(resolve => setTimeout(resolve, 0));

describe('c-orders', () => {

    // Nettoyage du DOM entre chaque test
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    // ─────────────────────────────────────────────────────
    // Cas nominal : Apex renvoie un montant positif
    // ─────────────────────────────────────────────────────
    it('affiche le montant total si Apex renvoie une valeur positive', async () => {
        getSumOrdersByAccount.mockResolvedValue(21500);

        const element = createElement('c-orders', { is: Orders });
        element.recordId = 'someAccountId';
        document.body.appendChild(element);

        await flushPromises();

        // La div success doit être présente
        const successBox = element.shadowRoot.querySelector('.slds-theme_success');
        expect(successBox).not.toBeNull();
        expect(successBox.textContent).toContain('21500');

        // La div erreur ne doit pas être présente
        const errorBox = element.shadowRoot.querySelector('.slds-theme_error');
        expect(errorBox).toBeNull();
    });

    // ─────────────────────────────────────────────────────
    // Apex renvoie null (aucune commande Activated)
    // ─────────────────────────────────────────────────────
    it('affiche une erreur si Apex renvoie null', async () => {
        getSumOrdersByAccount.mockResolvedValue(null);

        const element = createElement('c-orders', { is: Orders });
        element.recordId = 'someAccountId';
        document.body.appendChild(element);

        await flushPromises();

        const errorBox = element.shadowRoot.querySelector('.slds-theme_error');
        expect(errorBox).not.toBeNull();

        const successBox = element.shadowRoot.querySelector('.slds-theme_success');
        expect(successBox).toBeNull();
    });

    // ─────────────────────────────────────────────────────
    // Apex renvoie 0
    // ─────────────────────────────────────────────────────
    it('affiche une erreur si Apex renvoie 0', async () => {
        getSumOrdersByAccount.mockResolvedValue(0);

        const element = createElement('c-orders', { is: Orders });
        element.recordId = 'someAccountId';
        document.body.appendChild(element);

        await flushPromises();

        const errorBox = element.shadowRoot.querySelector('.slds-theme_error');
        expect(errorBox).not.toBeNull();
    });

    // ─────────────────────────────────────────────────────
    // Apex renvoie un montant négatif
    // ─────────────────────────────────────────────────────
    it('affiche une erreur si Apex renvoie une valeur négative', async () => {
        getSumOrdersByAccount.mockResolvedValue(-500);

        const element = createElement('c-orders', { is: Orders });
        element.recordId = 'someAccountId';
        document.body.appendChild(element);

        await flushPromises();

        const errorBox = element.shadowRoot.querySelector('.slds-theme_error');
        expect(errorBox).not.toBeNull();
    });

    // ─────────────────────────────────────────────────────
    // Apex lève une erreur (catch)
    // ─────────────────────────────────────────────────────
    it('affiche une erreur si Apex rejette la promesse', async () => {
        getSumOrdersByAccount.mockRejectedValue(new Error('Network error'));

        const element = createElement('c-orders', { is: Orders });
        element.recordId = 'someAccountId';
        document.body.appendChild(element);

        await flushPromises();

        const errorBox = element.shadowRoot.querySelector('.slds-theme_error');
        expect(errorBox).not.toBeNull();

        const successBox = element.shadowRoot.querySelector('.slds-theme_success');
        expect(successBox).toBeNull();
    });

    // ─────────────────────────────────────────────────────
    // Vérification que Apex est bien appelé avec le bon accountId
    // ─────────────────────────────────────────────────────
    it('appelle getSumOrdersByAccount avec le recordId du composant', async () => {
        getSumOrdersByAccount.mockResolvedValue(21500);

        const element = createElement('c-orders', { is: Orders });
        element.recordId = '001TESTACCOUNTID';
        document.body.appendChild(element);

        await flushPromises();

        expect(getSumOrdersByAccount).toHaveBeenCalledTimes(1);
        expect(getSumOrdersByAccount).toHaveBeenCalledWith({ accountId: '001TESTACCOUNTID' });
    });
});