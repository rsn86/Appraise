"""
Appraise evaluation framework

See LICENSE for usage details
"""
from django.apps import AppConfig
from django.db.models.signals import post_migrate


# pylint: disable-msg=missing-docstring
class DashboardConfig(AppConfig):
    name = 'Dashboard'

    def ready(self):
        from Dashboard.models import ensure_language_group_exists
        post_migrate.connect(ensure_language_group_exists, sender=self)
