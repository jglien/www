import { AstroSite, StackContext } from "sst/constructs";

export default function Site({ app, stack }: StackContext) {
  const johnDomain = "johnlien.me";
  let domainName = johnDomain;
  if (app.local) {
    domainName = `dev.${johnDomain}`;
  } else if (app.stage !== "prod") {
    domainName = `${app.stage}.${johnDomain}`;
  }

  const site = new AstroSite(stack, "site", {
    customDomain: {
      domainName,
      hostedZone: johnDomain,
    },
  });
  stack.addOutputs({
    url: site.customDomainUrl || site.url,
  });
}
