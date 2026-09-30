do $$
declare t text;
begin
  foreach t in array array[
    'knowledge_base_articles','training_modules','training_assignments','company_documents','vendors','inventory_items','equipment_assets','fleet_vehicles','safety_incidents','expense_reimbursements','mileage_entries','time_entries','backup_recovery_events'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
  end loop;
end $$;

create policy kb_read on public.knowledge_base_articles for select to authenticated using (private.company_access(company_id) and active and (visibility <> 'managers' or private.is_manager(company_id)));
create policy kb_write on public.knowledge_base_articles for insert to authenticated with check (private.is_manager(company_id) and created_by = (select auth.uid()));
create policy kb_update on public.knowledge_base_articles for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy training_modules_read on public.training_modules for select to authenticated using (private.company_access(company_id) and active);
create policy training_modules_write on public.training_modules for insert to authenticated with check (private.is_manager(company_id) and created_by = (select auth.uid()));
create policy training_modules_update on public.training_modules for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy training_assignments_read on public.training_assignments for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())));
create policy training_assignments_write on public.training_assignments for insert to authenticated with check (private.is_manager(company_id));
create policy training_assignments_update on public.training_assignments for update to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid()))) with check (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())));

create policy company_documents_read on public.company_documents for select to authenticated using (private.company_access(company_id) and (visibility <> 'managers' or private.is_manager(company_id)));
create policy company_documents_write on public.company_documents for insert to authenticated with check (private.company_access(company_id) and uploaded_by = (select auth.uid()));
create policy company_documents_update on public.company_documents for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy vendors_read on public.vendors for select to authenticated using (private.company_access(company_id));
create policy vendors_write on public.vendors for insert to authenticated with check (private.is_manager(company_id) and created_by = (select auth.uid()));
create policy vendors_update on public.vendors for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy inventory_read on public.inventory_items for select to authenticated using (private.company_access(company_id));
create policy inventory_write on public.inventory_items for insert to authenticated with check (private.is_manager(company_id));
create policy inventory_update on public.inventory_items for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy equipment_read on public.equipment_assets for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid()) or assigned_to is null));
create policy equipment_write on public.equipment_assets for insert to authenticated with check (private.is_manager(company_id));
create policy equipment_update on public.equipment_assets for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy fleet_read on public.fleet_vehicles for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or assigned_driver = (select auth.uid()) or assigned_driver is null));
create policy fleet_write on public.fleet_vehicles for insert to authenticated with check (private.is_manager(company_id));
create policy fleet_update on public.fleet_vehicles for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy safety_read on public.safety_incidents for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or reported_by = (select auth.uid()) or (job_id is not null and private.can_job(company_id,job_id))));
create policy safety_write on public.safety_incidents for insert to authenticated with check (private.company_access(company_id) and reported_by = (select auth.uid()) and (job_id is null or private.can_job(company_id,job_id)));
create policy safety_update on public.safety_incidents for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy expenses_read on public.expense_reimbursements for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or user_id = (select auth.uid())));
create policy expenses_write on public.expense_reimbursements for insert to authenticated with check (private.company_access(company_id) and user_id = (select auth.uid())) ;
create policy expenses_update on public.expense_reimbursements for update to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or user_id = (select auth.uid()))) with check (private.company_access(company_id) and (private.is_manager(company_id) or user_id = (select auth.uid())));
create policy mileage_read on public.mileage_entries for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or user_id = (select auth.uid())));
create policy mileage_write on public.mileage_entries for insert to authenticated with check (private.company_access(company_id) and user_id = (select auth.uid())) ;
create policy mileage_update on public.mileage_entries for update to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or user_id = (select auth.uid()))) with check (private.company_access(company_id) and (private.is_manager(company_id) or user_id = (select auth.uid())));
create policy time_read on public.time_entries for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or user_id = (select auth.uid())));
create policy time_write on public.time_entries for insert to authenticated with check (private.company_access(company_id) and user_id = (select auth.uid())) ;
create policy time_update on public.time_entries for update to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or user_id = (select auth.uid()))) with check (private.company_access(company_id) and (private.is_manager(company_id) or user_id = (select auth.uid())));

create policy backup_read on public.backup_recovery_events for select to authenticated using (private.is_manager(company_id));
create policy backup_write on public.backup_recovery_events for insert to authenticated with check (private.is_manager(company_id));
create policy backup_update on public.backup_recovery_events for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
