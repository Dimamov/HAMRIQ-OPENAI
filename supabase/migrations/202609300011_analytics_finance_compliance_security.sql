do $$ declare t text; begin
  foreach t in array array['kpi_goals','sales_forecasts','business_health_items','anomaly_alerts','payment_transactions','invoices','contract_compliance_checks','permits','warranty_records','service_tickets','renewal_items','integration_connections'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
  end loop;
end $$;
create policy kpi_goals_manager on public.kpi_goals for all to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy sales_forecasts_manager on public.sales_forecasts for all to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy business_health_manager on public.business_health_items for all to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy anomaly_manager on public.anomaly_alerts for all to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy payments_manager on public.payment_transactions for all to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy invoices_manager on public.invoices for all to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy contract_checks_manager on public.contract_compliance_checks for all to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy permits_read on public.permits for select to authenticated using(private.can_job(company_id,job_id));
create policy permits_manager_write on public.permits for all to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy warranty_read on public.warranty_records for select to authenticated using(private.can_job(company_id,job_id));
create policy warranty_manager_write on public.warranty_records for all to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy service_read on public.service_tickets for select to authenticated using((job_id is not null and private.can_job(company_id,job_id)) or private.is_manager(company_id) or assigned_to=(select auth.uid()));
create policy service_write on public.service_tickets for insert to authenticated with check(private.company_access(company_id) and (private.is_manager(company_id) or assigned_to=(select auth.uid())));
create policy service_update on public.service_tickets for update to authenticated using(private.is_manager(company_id) or assigned_to=(select auth.uid())) with check(private.is_manager(company_id) or assigned_to=(select auth.uid()));
create policy renewals_manager on public.renewal_items for all to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy integrations_manager on public.integration_connections for all to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
