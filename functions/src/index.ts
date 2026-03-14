/**
 * Cloud Functions entry point.
 *
 * Firebase discovers exported functions from this file.  All handler logic
 * lives in dedicated modules — this file only re-exports them.
 */

export { handleChatMessage } from "./chat_handler";
