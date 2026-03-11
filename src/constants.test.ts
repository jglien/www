import { describe, it, expect } from "vitest";
import { contact } from "./constants";

describe("contact", () => {
  it("every entry has a non-empty title and link", () => {
    for (const c of contact) {
      expect(c.title.trim()).not.toBe("");
      expect(c.link.trim()).not.toBe("");
    }
  });

  it("links use a recognised scheme", () => {
    for (const c of contact) {
      expect(c.link).toMatch(/^(https?:|mailto:)/);
    }
  });
});
