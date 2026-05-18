CREATE POLICY b2b_agreements_storage_insert
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'b2b-signatures');

CREATE POLICY b2b_agreements_storage_select
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (bucket_id = 'b2b-signatures');
