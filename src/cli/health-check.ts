import { execSync } from "node:child_process";
import fs from "node:fs";

function log(msg: string, status: "ok" | "fail" | "info" = "info") {
  const icon = status === "ok" ? "✅" : status === "fail" ? "❌" : "ℹ️";
  console.log(`${icon} ${msg}`);
}

async function checkHealth() {
  console.log("\n--- OpenClaw Cloud Health Diagnostic ---\n");

  // 1. Permission Check
  try {
    const stateDir = process.env.OPENCLAW_STATE_DIR || "/home/node/.openclaw";
    const testFile = `${stateDir}/health_test_${Date.now()}.tmp`;
    fs.writeFileSync(testFile, "test");
    fs.unlinkSync(testFile);
    log(`Write permissions for ${stateDir}: OK`, "ok");
  } catch (e: unknown) {
    const error = e as Error;
    log(`Write permissions failed: ${error.message}`, "fail");
  }

  // 2. Dependency Check: gog
  try {
    const version = execSync("gog --version").toString().trim();
    log(`gog CLI: ${version}`, "ok");
  } catch {
    log("gog CLI: Not found or failed", "fail");
  }

  // 3. Dependency Check: gcloud
  try {
    const version = execSync("gcloud --version").toString().trim().split("\n")[0];
    log(`gcloud SDK: ${version}`, "ok");
  } catch {
    log("gcloud SDK: Not found (Required for Google Hub setup)", "fail");
  }

  // 4. Telegram Connectivity
  const token = process.env.TELEGRAM_BOT_TOKEN;
  if (token) {
    try {
      const resp = await fetch(`https://api.telegram.org/bot${token}/getMe`);
      const data = await resp.json();
      if (data.ok) {
        log(`Telegram API: Linked as @${data.result.username}`, "ok");
      } else {
        log(`Telegram API: Error - ${data.description}`, "fail");
      }
    } catch (e: unknown) {
      const error = e as Error;
      log(`Telegram API: Network Error - ${error.message}`, "fail");
    }
  } else {
    log("TELEGRAM_BOT_TOKEN: Missing in env", "fail");
  }

  console.log("\n----------------------------------------\n");
}

checkHealth().catch(console.error);
