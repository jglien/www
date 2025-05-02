import { AstroSite, type StackContext } from "sst/constructs";
import { ResponseHeadersPolicy } from "aws-cdk-lib/aws-cloudfront";

export default function Site({ app, stack }: StackContext) {
  const johnDomain = "johnlien.me";
  let domainName = johnDomain;
  if (app.local) {
    domainName = `dev.${johnDomain}`;
  } else if (app.stage !== "prod") {
    domainName = `${app.stage}.${johnDomain}`;
  }

  const site = new AstroSite(stack, "site", {
    runtime: "nodejs20.x",
    customDomain: {
      domainName,
      hostedZone: johnDomain,
    },
    cdk: {
      responseHeadersPolicy: ResponseHeadersPolicy.CORS_ALLOW_ALL_ORIGINS_AND_SECURITY_HEADERS,
    },
  });
  stack.addOutputs({
    url: site.customDomainUrl || site.url,
  });
}
