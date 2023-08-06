import type { SSTConfig } from "sst";
import Site from "./stacks/Site";

export default {
  config(_input) {
    return {
      name: "www",
      region: process.env.AWS_REGION,
      profile: process.env.AWS_PROFILE,
    };
  },
  stacks(app) {
    app.stack(Site);
  },
} satisfies SSTConfig;
