/// Centralised constants for the frontend — every shared string or list used
/// in comparisons, defaults, or routing lives here so nothing is scattered
/// across multiple files.

// ─── App Identity ────────────────────────────────────────────────────────────
const String appName = 'Pathora AI';

// ─── Protocol ────────────────────────────────────────────────────────────────
const String startMessage = '__start__';

// ─── Roles ───────────────────────────────────────────────────────────────────
const String roleUser = 'user';
const String roleAssistant = 'assistant';

// ─── Routes ──────────────────────────────────────────────────────────────────
const String routeHome = '/';
const String routeChat = '/chat';
const String routeAdmin = '/admin';

// ─── API Endpoints (relative to base URL) ────────────────────────────────────
const String endpointChat = '/handleChatMessage';
const String endpointAdminOpportunities = '/admin/opportunities';

// ─── Opportunity Types ───────────────────────────────────────────────────────
const String typeScholarship = 'scholarship';
const String typeInternship = 'internship';
const String typeFellowship = 'fellowship';
const String typeResearch = 'research';
const String typeExchange = 'exchange';
const String typeSummit = 'summit';

const List<String> opportunityTypes = [
  typeScholarship,
  typeInternship,
  typeFellowship,
  typeResearch,
  typeExchange,
  typeSummit,
];

// ─── Education Levels ────────────────────────────────────────────────────────
const String levelAny = 'any';
const String levelUndergraduate = 'undergraduate';
const String levelGraduate = 'graduate';
const String levelPhd = 'phd';

const List<String> educationLevels = [
  levelAny,
  levelUndergraduate,
  levelGraduate,
  levelPhd,
];

// ─── Opportunity Sources ─────────────────────────────────────────────────────
const String sourceManual = 'manual';
const String sourceAiGenerated = 'ai-generated';
