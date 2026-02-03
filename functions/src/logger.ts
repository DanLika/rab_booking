/**
 * Logger utility for Firebase Cloud Functions
 *
 * Provides consistent logging across all Cloud Functions
 * Uses firebase-functions/logger for structured logging
 * Integrates with Sentry for error tracking (production only)
 */

import * as functions from "firebase-functions";
import {captureException, captureMessage, addBreadcrumb} from "./sentry";

/**
 * Log levels
 */
export enum LogLevel {
  DEBUG = "debug",
  INFO = "info",
  WARN = "warn",
  ERROR = "error",
}

/**
 * Logger class for Cloud Functions
 */
export class Logger {
  /**
   * Log an info message
   * @param message - The message to log
   * @param data - Optional structured data
   */
  static info(message: string, data?: Record<string, any>): void {
    if (data) {
      functions.logger.info(message, data);
    } else {
      functions.logger.info(message);
    }
  }

  /**
   * Log a debug message
   * @param message - The message to log
   * @param data - Optional structured data
   */
  static debug(message: string, data?: Record<string, any>): void {
    if (data) {
      functions.logger.debug(message, data);
    } else {
      functions.logger.debug(message);
    }
  }

  /**
   * Log a warning message
   * @param message - The message to log
   * @param data - Optional structured data
   */
  static warn(message: string, data?: Record<string, any>): void {
    if (data) {
      functions.logger.warn(message, data);
    } else {
      functions.logger.warn(message);
    }
  }

  /**
   * Log an error message
   * Also sends to Sentry for error tracking
   * @param message - The message to log
   * @param error - Optional error object
   * @param data - Optional additional structured data
   */
  static error(message: string, error?: Error | unknown, data?: Record<string, any>): void {
    const logData: Record<string, any> = {...data};

    if (error) {
      if (error instanceof Error) {
        logData.error = {
          message: error.message,
          stack: error.stack,
          name: error.name,
        };
      } else if (error && typeof error === "object") {
        // Handle non-Error objects (e.g., API responses, plain objects)
        try {
          logData.error = JSON.stringify(error, null, 2);
        } catch {
          logData.error = String(error);
        }
      } else {
        logData.error = String(error);
      }
    }

    if (Object.keys(logData).length > 0) {
      functions.logger.error(message, logData);
    } else {
      functions.logger.error(message);
    }

    // Send to Sentry for error tracking (fire-and-forget)
    if (error) {
      captureException(error, {message, ...data});
    } else {
      // If no error object, send as message
      captureMessage(message, "error", data);
    }
  }

  /**
   * Log a success operation
   * @param message - The message to log
   * @param data - Optional structured data
   */
  static success(message: string, data?: Record<string, any>): void {
    const logData = {...data, status: "success"};
    functions.logger.info(message, logData);
  }

  /**
   * Log the start of an operation
   * Also adds breadcrumb for Sentry error context
   * @param operation - The operation name
   * @param data - Optional structured data
   */
  static operation(operation: string, data?: Record<string, any>): void {
    const logData = {...data, operation, phase: "start"};
    functions.logger.info(`Starting: ${operation}`, logData);

    // Add breadcrumb for Sentry (helps debug errors)
    addBreadcrumb(`Starting: ${operation}`, "operation", data);
  }

  /**
   * Log the completion of an operation
   * Also adds breadcrumb for Sentry error context
   * @param operation - The operation name
   * @param data - Optional structured data
   */
  static complete(operation: string, data?: Record<string, any>): void {
    const logData = {...data, operation, phase: "complete"};
    functions.logger.info(`Completed: ${operation}`, logData);

    // Add breadcrumb for Sentry (helps debug errors)
    addBreadcrumb(`Completed: ${operation}`, "operation", data);
  }
}

/**
 * Convenience functions for common logging patterns
 */

/**
 * Log info message
 */
export const logInfo = (message: string, data?: Record<string, any>) => Logger.info(message, data);

/**
 * Log debug message
 */
export const logDebug = (message: string, data?: Record<string, any>) => Logger.debug(message, data);

/**
 * Log warning message
 */
export const logWarn = (message: string, data?: Record<string, any>) => Logger.warn(message, data);

/**
 * Log error message
 */
export const logError = (message: string, error?: Error | unknown, data?: Record<string, any>) =>
  Logger.error(message, error, data);

/**
 * Log success message
 */
export const logSuccess = (message: string, data?: Record<string, any>) => Logger.success(message, data);

/**
 * Log operation start
 */
export const logOperation = (operation: string, data?: Record<string, any>) => Logger.operation(operation, data);

/**
 * Log operation complete
 */
export const logComplete = (operation: string, data?: Record<string, any>) => Logger.complete(operation, data);
