import { WorkerEntrypoint } from "cloudflare:workers";
import type { Env } from "./types";

export interface IceServerConfiguration {
  iceServers: unknown;
}

export async function createIceServers(env: Env): Promise<IceServerConfiguration> {
  if (!env.TURN_KEY_ID || !env.TURN_KEY_API_TOKEN) {
    return { iceServers: [{ urls: ["stun:stun.cloudflare.com:3478"] }] };
  }
  const response = await fetch(
    `https://rtc.live.cloudflare.com/v1/turn/keys/${encodeURIComponent(env.TURN_KEY_ID)}/credentials/generate-ice-servers`,
    {
      method: "POST",
      headers: { authorization: `Bearer ${env.TURN_KEY_API_TOKEN}`, "content-type": "application/json" },
      body: JSON.stringify({ ttl: 14400 })
    }
  );
  if (!response.ok) throw new Error("Voice connection is temporarily unavailable.");
  const data = await response.json() as { iceServers?: unknown };
  if (!Array.isArray(data.iceServers) || data.iceServers.length === 0) {
    throw new Error("Voice connection is temporarily unavailable.");
  }
  return { iceServers: data.iceServers };
}

// Internal service binding only. TestFlight authenticates its own active-table
// players before calling this method; production TURN secrets stay in production.
export class VoiceRelay extends WorkerEntrypoint<Env> {
  async createIceServers(): Promise<IceServerConfiguration> {
    return createIceServers(this.env);
  }
}
