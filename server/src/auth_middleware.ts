import { Request, Response, NextFunction } from "express";
import { admin } from "./firebase";

export interface AuthedRequest extends Request {
  user?: { uid: string; email?: string; name?: string };
}

export async function firebaseAuthMiddleware(
  req: AuthedRequest,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith("Bearer ")) {
    return next();
  }

  const token = authHeader.slice(7);

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      name: decoded.name,
    };
  } catch {
    // Token invalid or expired — proceed without user context.
    // Individual routes can decide whether to reject unauthenticated requests.
  }

  next();
}
