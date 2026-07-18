import Testing
@testable import BreathRelaxStretch

// Regression coverage for the "looks configured, isn't" bug class: the
// dashboard URL (supabase.com/dashboard/project/...) is a real, non-placeholder
// URL, so a check that only looked for the literal "YOUR_PROJECT" placeholder
// string incorrectly reported isConfigured == true and let the app attempt
// real network calls against a host that returns HTML/404, not JSON.
struct SupabaseServiceTests {

    @Test func rejectsTheDashboardURLSpecifically() {
        #expect(!SupabaseService.isValidAPIHost("https://supabase.com/dashboard/project/wmsutfittuxrvcwuywrk"))
    }

    @Test func acceptsARealProjectAPIHost() {
        #expect(SupabaseService.isValidAPIHost("https://wmsutfittuxrvcwuywrk.supabase.co"))
    }

    @Test func rejectsMalformedOrHostlessURLs() {
        #expect(!SupabaseService.isValidAPIHost("not a url"))
        #expect(!SupabaseService.isValidAPIHost(""))
    }

    @Test func rejectsLookalikeHostsThatArentActuallySupabaseCo() {
        // A host merely containing "supabase.co" isn't enough — must be a real subdomain of it.
        #expect(!SupabaseService.isValidAPIHost("https://supabase.co.evil.com"))
        #expect(!SupabaseService.isValidAPIHost("https://notsupabase.co"))
    }

    @Test func currentlyConfiguredCredentialsPassTheRealCheck() {
        // Guards against this regressing back to a non-API host in the future.
        #expect(SupabaseService.isConfigured)
    }
}
