import Foundation
import Supabase

enum TrimrConfig {
    static let supabaseURL = URL(string: "https://svgsgmgksazhcpmzyhiu.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN2Z3NnbWdrc2F6aGNwbXp5aGl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM5OTY5MzMsImV4cCI6MjA4OTU3MjkzM30.wfNCyhOlzDvqhhxUr7q29czlm72soyUsN3DoTRNLKvQ"
}

enum Supa {
    static let client: SupabaseClient = SupabaseClient(
        supabaseURL: TrimrConfig.supabaseURL,
        supabaseKey: TrimrConfig.supabaseAnonKey
    )
}
