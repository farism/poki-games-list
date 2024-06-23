globalThis.__tcfapi = () => {};

const list = [];

describe("template spec", () => {
  beforeEach(() => {
    Cypress.automation("remote:debugger:protocol", {
      command: "Network.clearBrowserCache",
    });
  });
  
  it("passes", () => {
    cy.visit("https://poki.com/en/categories");
    cy.wait(2000);

    // let url = 'https://poki.com/en/g/pixel-realms'

    // cy.intercept('*dmloader*', (req) => {
    //   list.push(url)
    // })
  });
});
