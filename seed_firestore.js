/**
 * Seed script — populates the Firestore "opportunities" collection.
 *
 * Usage:
 *   1. Set GOOGLE_APPLICATION_CREDENTIALS to your service-account key, OR
 *      run against the emulator by setting FIRESTORE_EMULATOR_HOST=127.0.0.1:8081
 *   2. node seed_firestore.js
 */

const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const opportunities = [
  {
    title: "Erasmus Mundus Joint Master Scholarship",
    type: "scholarship",
    country: "Europe",
    field: "Multiple Fields",
    educationLevel: "graduate",
    deadline: "December 2026",
    description:
      "Fully funded master's degree in Europe covering tuition, travel, and living costs across multiple EU universities.",
    applicationLink: "https://www.eacea.ec.europa.eu/scholarships/erasmus-mundus-catalogue_en",
  },
  {
    title: "Google Summer of Code",
    type: "internship",
    country: "Global (Remote)",
    field: "Computer Science",
    educationLevel: "undergraduate",
    deadline: "March 2026",
    description:
      "A global program where students work on open-source projects with mentoring organizations during summer.",
    applicationLink: "https://summerofcode.withgoogle.com/",
  },
  {
    title: "Chevening Scholarship",
    type: "scholarship",
    country: "United Kingdom",
    field: "Multiple Fields",
    educationLevel: "graduate",
    deadline: "November 2026",
    description:
      "UK government's flagship scholarship for outstanding emerging leaders to study a one-year master's in the UK.",
    applicationLink: "https://www.chevening.org/",
  },
  {
    title: "DAAD Scholarship",
    type: "scholarship",
    country: "Germany",
    field: "Multiple Fields",
    educationLevel: "graduate",
    deadline: "October 2026",
    description:
      "Scholarships for international students to study at German universities, funded by the German Academic Exchange Service.",
    applicationLink: "https://www.daad.de/en/",
  },
  {
    title: "Microsoft Explore Internship",
    type: "internship",
    country: "United States",
    field: "Computer Science",
    educationLevel: "undergraduate",
    deadline: "September 2026",
    description:
      "A 12-week internship for first- and second-year students exploring software engineering and PM at Microsoft.",
    applicationLink: "https://careers.microsoft.com/",
  },
  {
    title: "Fulbright Foreign Student Program",
    type: "fellowship",
    country: "United States",
    field: "Multiple Fields",
    educationLevel: "graduate",
    deadline: "February 2026",
    description:
      "Enables graduate students and young professionals to study and conduct research in the United States.",
    applicationLink: "https://foreign.fulbrightonline.org/",
  },
  {
    title: "AIESEC Global Volunteer",
    type: "exchange",
    country: "Global",
    field: "Multiple Fields",
    educationLevel: "undergraduate",
    deadline: "Rolling",
    description:
      "Cross-cultural volunteer experiences in 120+ countries focused on UN Sustainable Development Goals.",
    applicationLink: "https://aiesec.org/",
  },
  {
    title: "One Young World Summit",
    type: "summit",
    country: "Global",
    field: "Leadership",
    educationLevel: "any",
    deadline: "May 2026",
    description:
      "A global summit bringing together young leaders from 190+ countries to address global challenges.",
    applicationLink: "https://www.oneyoungworld.com/",
  },
  {
    title: "Korean Government Scholarship (KGSP)",
    type: "scholarship",
    country: "South Korea",
    field: "Multiple Fields",
    educationLevel: "undergraduate",
    deadline: "March 2026",
    description:
      "Full scholarship covering tuition, airfare, living expenses, and Korean language training in South Korea.",
    applicationLink: "https://www.studyinkorea.go.kr/",
  },
  {
    title: "Amazon Future Engineer Internship",
    type: "internship",
    country: "United States",
    field: "Computer Science",
    educationLevel: "undergraduate",
    deadline: "January 2026",
    description:
      "A summer internship at Amazon for students from underrepresented backgrounds in computer science.",
    applicationLink: "https://www.amazonfutureengineer.com/",
  },
  {
    title: "Schwarzman Scholars",
    type: "fellowship",
    country: "China",
    field: "Leadership & Public Policy",
    educationLevel: "graduate",
    deadline: "September 2026",
    description:
      "A one-year master's program at Tsinghua University focused on leadership, China, and global affairs.",
    applicationLink: "https://www.schwarzmanscholars.org/",
  },
  {
    title: "SAKURA Exchange Program",
    type: "exchange",
    country: "Japan",
    field: "Science & Technology",
    educationLevel: "undergraduate",
    deadline: "Varies",
    description:
      "A short-term exchange program inviting Asian youth to Japan for science and technology experiences.",
    applicationLink: "https://ssp.jst.go.jp/",
  },
  {
    title: "CERN Summer Student Programme",
    type: "research",
    country: "Switzerland",
    field: "Physics & Engineering",
    educationLevel: "undergraduate",
    deadline: "January 2026",
    description:
      "Work with world-class researchers at CERN on cutting-edge particle physics experiments and computing projects.",
    applicationLink: "https://home.cern/summer-student-programme",
  },
  {
    title: "MIT Undergraduate Research (UROP)",
    type: "research",
    country: "United States",
    field: "Multiple Fields",
    educationLevel: "undergraduate",
    deadline: "Rolling",
    description:
      "Join MIT research projects across all departments — open to visiting undergraduates with strong academic records.",
    applicationLink: "https://urop.mit.edu/",
  },
  {
    title: "Max Planck Research Internship",
    type: "research",
    country: "Germany",
    field: "Science & Technology",
    educationLevel: "graduate",
    deadline: "March 2026",
    description:
      "Research internship at one of the 86 Max Planck Institutes in natural sciences, social sciences, or humanities.",
    applicationLink: "https://www.mpg.de/",
  },
  {
    title: "ETH Zurich Excellence Scholarship",
    type: "scholarship",
    country: "Switzerland",
    field: "Engineering",
    educationLevel: "graduate",
    deadline: "December 2026",
    description:
      "Fully funded scholarship at ETH Zurich for outstanding master's students in engineering and natural sciences.",
    applicationLink: "https://ethz.ch/students/en/studies/financial/scholarships.html",
  },
  {
    title: "World Economic Forum Global Shapers Summit",
    type: "summit",
    country: "Global",
    field: "Leadership",
    educationLevel: "any",
    deadline: "June 2026",
    description:
      "Annual summit for young leaders under 30 working on local and global challenges through the WEF network.",
    applicationLink: "https://www.globalshapers.org/",
  },
];

async function seed() {
  console.log("Seeding Firestore with sample opportunities...\n");

  for (const opp of opportunities) {
    const ref = await db.collection("opportunities").add(opp);
    console.log(`  Added: ${opp.title} (${ref.id})`);
  }

  console.log(`\nDone — ${opportunities.length} opportunities seeded.`);
  process.exit(0);
}

seed().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
