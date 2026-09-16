import * as sdk from "@earendil-works/pi-coding-agent";

type ChildModelOptions = Pick<
  sdk.CreateAgentSessionOptions,
  Extract<
    keyof sdk.CreateAgentSessionOptions,
    "modelRuntime" | "modelRegistry" | "authStorage"
  >
>;

/** Reuse live parent models/auth with either the injected host SDK or 0.80.7. */
export function childModelOptions(
  modelRegistry: sdk.ModelRegistry,
): ChildModelOptions {
  // 0.85.1 has no public unwrap API. Its facade stores the original runtime
  // in a TS-private field. Check the host constructor, never rebuild auth.
  const parent: unknown = modelRegistry;
  if ("ModelRuntime" in sdk) {
    if (
      typeof sdk.ModelRuntime !== "function" ||
      typeof parent !== "object" ||
      parent === null ||
      !("runtime" in parent) ||
      !(parent.runtime instanceof sdk.ModelRuntime)
    ) {
      throw new Error("Cannot inherit the parent pi model runtime.");
    }
    // modelRegistry is ignored by the new SDK; retaining it lets this boundary
    // compile against the old declarations without importing a missing export.
    return { modelRegistry, modelRuntime: parent.runtime } as ChildModelOptions;
  }
  if (!("authStorage" in modelRegistry)) {
    throw new Error("Cannot inherit the parent pi auth storage.");
  }
  return {
    modelRegistry,
    authStorage: modelRegistry.authStorage,
  } as ChildModelOptions;
}
