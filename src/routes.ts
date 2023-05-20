import { contentType } from "std/media_types/content_type.ts";
import * as path from "std/path/mod.ts";

import * as Eta from "eta";

import { compile } from "./elm/compile.ts";
import { findLatestBundle } from "./elm/bundle.ts";
import * as env from "./env.ts";
import * as response from "./response/mod.ts";

Eta.configure({
  views: path.join(Deno.cwd(), "web"),
});

type Route = {
  debug?: true;
  pattern: URLPattern;
  handler: (
    pattern: URLPatternResult,
    request: Request,
  ) => Response | Promise<Response>;
};

const latestBundle = await findLatestBundle();

export const routes: Route[] = [
  {
    pattern: new URLPattern({ pathname: "/" }),
    async handler(): Promise<Response> {
      const bundle = env.development ? "index.js" : latestBundle;

      if (bundle === undefined) {
        return new Response(null, { status: 404 });
      }

      const ssr = await Eta.renderFileAsync("index", {
        bundle,
        ssr: "",
      });

      return new Response(ssr, {
        status: 200,
        headers: {
          "content-type": "text/html",
        },
      });
    },
  },
  {
    debug: true,
    pattern: new URLPattern({ pathname: "/index.js" }),
    async handler(): Promise<Response> {
      compile("app/browser/Main.elm", "public/index.js");
      return await response.fileStream(
        "public/index.js",
        "application/javascript; charset=UTF-8",
      );
    },
  },
  {
    pattern: new URLPattern({ pathname: "/assets/:file" }),
    async handler(pattern): Promise<Response> {
      const filePath = path.join("web", pattern.pathname.groups.file);
      return await response.fileStream(
        filePath,
        contentType(path.extname(pattern.pathname.groups.file)),
      );
    },
  },
];
