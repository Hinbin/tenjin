# frozen_string_literal: true

# Phase 4 reward-shop catalog seeding. Thin wrapper around the idempotent seeder service so the
# data + pricing live in one place (Customisation::SeedCosmetics) and `rails db:seed` stays clean.
# Skip the default-equip backfill in production (it iterates every student) — Theme::Selection
# falls back to defaults regardless, and the equip happens lazily on a student's first shop visit.
Customisation::SeedCosmetics.call(backfill: !Rails.env.production?)
