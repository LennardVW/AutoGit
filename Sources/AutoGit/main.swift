import Foundation

// MARK: - AutoGit
/// Automatic commit message generation based on git diffs
/// Uses heuristics to analyze changes and generate meaningful commits

@main
struct AutoGit {
    static func main() async {
        let autogit = AutoGitCore()
        await autogit.run()
    }
}

@MainActor
final class AutoGitCore {
    func run() async {
        print("""
        🤖 AutoGit - Automatic Commit Generation
        
        Commands:
          suggest           Analyze staged changes and suggest commits
          auto              Auto-commit with generated message
          log               Show recent auto-generated commits
          config            Configure auto-git settings
          install-hook      Install git post-commit hook
          help              Show this help
          quit              Exit
        """)
        
        while true {
            print("> ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else { continue }
            
            switch input {
            case "suggest", "s":
                await suggestCommits()
            case "auto", "a":
                await autoCommit()
            case "log", "l":
                showLog()
            case "config", "c":
                configure()
            case "install-hook":
                installHook()
            case "help", "h":
                showHelp()
            case "quit", "q", "exit":
                print("👋 Goodbye!")
                return
            default:
                print("Unknown command. Type 'help' for options.")
            }
        }
    }
    
    func suggestCommits() async {
        print("🔍 Analyzing changes...")
        
        // Get staged diff
        let diff = runGitCommand(["diff", "--cached", "--stat"])
        let fullDiff = runGitCommand(["diff", "--cached"])
        
        guard !diff.isEmpty else {
            print("⚠️  No staged changes. Run 'git add' first.")
            return
        }
        
        print("\n📊 Changes:")
        print(diff)
        
        // Generate suggestions
        let suggestions = generateCommitMessages(diff: fullDiff)
        
        print("\n💡 Suggested commits:")
        for (index, suggestion) in suggestions.enumerated() {
            print("   \(index + 1). \(suggestion)")
        }
        
        print("\nUse 'auto' to commit with the best suggestion")
    }
    
    func autoCommit() async {
        let diff = runGitCommand(["diff", "--cached"])
        
        guard !diff.isEmpty else {
            print("⚠️  No staged changes to commit")
            return
        }
        
        let message = generateBestCommitMessage(diff: diff)
        print("🤖 Generated message: \"\(message)\"")
        print("Commit? (y/n): ", terminator: "")
        
        guard let response = readLine()?.lowercased(), response == "y" || response == "yes" else {
            print("❌ Cancelled")
            return
        }
        
        // Execute commit
        let result = runGitCommand(["commit", "-m", message])
        
        if result.contains("error") || result.contains("fatal") {
            print("❌ Commit failed: \(result)")
        } else {
            print("✅ Committed: \(message)")
            
            // Store in log
            logCommit(message: message, date: Date())
        }
    }
    
    private func generateCommitMessages(diff: String) -> [String] {
        var messages: [String] = []
        
        // Analyze diff patterns
        let lines = diff.components(separatedBy: .newlines)
        
        // Check for file patterns
        let addedFiles = lines.filter { $0.hasPrefix("+++ b/") && !$0.contains("/dev/null") }
        let removedFiles = lines.filter { $0.hasPrefix("--- a/") && !$0.contains("/dev/null") }
        let modifications = lines.filter { $0.hasPrefix("@@") }
        
        // Detect change types
        let isRefactor = diff.contains("refactor") || diff.contains("rename")
        let isFix = diff.contains("fix:") || diff.contains("bug") || diff.contains("error")
        let isFeature = diff.contains("feat:") || diff.contains("add:") || diff.contains("new:")
        let isDocs = diff.contains(".md") || diff.contains("README") || diff.contains("docs")
        let isTest = diff.contains("test") || diff.contains("spec")
        
        // Generate based on detected patterns
        if isFix {
            messages.append("fix: Resolve issue in modified components")
            messages.append("fix: Correct logic error")
        }
        
        if isFeature {
            messages.append("feat: Add new functionality")
            messages.append("feat: Implement requested feature")
        }
        
        if isRefactor {
            messages.append("refactor: Improve code structure")
            messages.append("refactor: Simplify implementation")
        }
        
        if isDocs {
            messages.append("docs: Update documentation")
            messages.append("docs: Add README updates")
        }
        
        if isTest {
            messages.append("test: Add unit tests")
            messages.append("test: Improve test coverage")
        }
        
        // Generic suggestions based on file changes
        if !addedFiles.isEmpty && removedFiles.isEmpty {
            messages.append("feat: Add \(addedFiles.count) new files")
        }
        
        if !removedFiles.isEmpty {
            messages.append("chore: Remove unused files")
        }
        
        if modifications.count > 5 {
            messages.append("refactor: Major changes across multiple files")
        }
        
        // Default suggestions
        if messages.isEmpty {
            messages.append("chore: Update project files")
            messages.append("feat: Implement changes")
            messages.append("refactor: Code improvements")
        }
        
        return Array(messages.prefix(5))
    }
    
    private func generateBestCommitMessage(diff: String) -> String {
        let suggestions = generateCommitMessages(diff: diff)
        return suggestions.first ?? "chore: Update files"
    }
    
    private func runGitCommand(_ args: [String]) -> String {
        let task = Process()
        task.launchPath = "/usr/bin/git"
        task.arguments = args
        task.currentDirectoryPath = FileManager.default.currentDirectoryPath
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        try? task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private func logCommit(message: String, date: Date) {
        // In production: Save to local database or file
    }
    
    private func showLog() {
        print("📜 Recent auto-generated commits:")
        print("   (Feature: Connect to git log)")
    }
    
    private func configure() {
        print("⚙️  Configuration:")
        print("   - Commit style: conventional")
        print("   - Auto-push: disabled")
        print("   - Confirmation: enabled")
    }
    
    private func installHook() {
        print("🔧 Installing post-commit hook...")
        // Would install git hook to auto-suggest on commit
        print("✅ Hook installed (simulated)")
    }
    
    private func showHelp() {
        print("""
        Commands:
          suggest      Analyze staged changes and suggest commits
          auto         Auto-commit with generated message
          log          Show recent auto-generated commits
          config       Configure settings
          install-hook Install git hook
          help         Show this help
          quit         Exit
        """)
    }
}
