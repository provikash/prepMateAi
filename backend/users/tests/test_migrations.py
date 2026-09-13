from django.db import connection
from django.db.migrations.executor import MigrationExecutor
from django.test import TransactionTestCase


class AccountMigrationTests(TransactionTestCase):
    def test_upgrade_preserves_identity_password_profile_and_normalizes(self):
        old = [("users", "0008_userprofile")]
        executor = MigrationExecutor(connection)
        latest = executor.loader.graph.leaf_nodes()
        executor.migrate(old)
        try:
            apps = executor.loader.project_state(old).apps
            user = apps.get_model("users", "User").objects.create(email="Legacy@Example.COM", username="Legacy@Example.COM", name="Legacy", password="existing-hashed-password", is_verified=True)
            profile = apps.get_model("users", "UserProfile").objects.create(user=user, bio="Existing biography")
            executor = MigrationExecutor(connection)
            executor.migrate(latest)
            apps = executor.loader.project_state(latest).apps
            migrated = apps.get_model("users", "User").objects.get(pk=user.pk)
            self.assertEqual(migrated.email, "legacy@example.com")
            self.assertEqual(migrated.password, "existing-hashed-password")
            self.assertTrue(migrated.is_verified)
            self.assertEqual(migrated.created_at, migrated.date_joined)
            self.assertEqual(apps.get_model("users", "UserProfile").objects.get(pk=profile.pk).bio, "Existing biography")
        finally:
            MigrationExecutor(connection).migrate(latest)

    def test_conflicting_email_preflight_fails_without_deleting(self):
        import importlib
        module = importlib.import_module("users.migrations.0009_emailotp_alter_user_options_user_created_at_and_more")
        from unittest.mock import Mock
        users = Mock()
        users.values_list.return_value.iterator.return_value = iter(["same@example.com", "SAME@example.com"])
        apps = Mock()
        apps.get_model.return_value.objects.using.return_value = users
        editor = Mock()
        with self.assertRaisesRegex(RuntimeError, "Conflicting normalized"):
            module.normalize_existing_users(apps, editor)
        users.filter.assert_not_called()
