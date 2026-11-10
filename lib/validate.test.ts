import { describe, expect, it } from "vitest";
import { safeOpportunityReturnPath } from "./validate";

describe("safeOpportunityReturnPath", () => {
  it("accepts canonical scholarship and opportunity paths", () => {
    expect(safeOpportunityReturnPath("/scholarship/example-award-1234")).toBe(
      "/scholarship/example-award-1234",
    );
    expect(safeOpportunityReturnPath("/opportunity/tech-program_2027")).toBe(
      "/opportunity/tech-program_2027",
    );
  });

  it("rejects open redirects and non-opportunity internal paths", () => {
    expect(safeOpportunityReturnPath("//evil.example/collect")).toBe("/dashboard");
    expect(safeOpportunityReturnPath("/admin/users")).toBe("/dashboard");
    expect(safeOpportunityReturnPath("/opportunity/a?next=/admin")).toBe("/dashboard");
    expect(safeOpportunityReturnPath("/opportunity/\\evil")).toBe("/dashboard");
  });
});
