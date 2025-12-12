'use client'

import { useEffect, useState } from 'react'
import { usePathname, useRouter } from 'next/navigation'
import Link from 'next/link'
import { useAuth } from '@/components/providers/auth-provider'
import { createClient } from '@/lib/supabase/client'
import { cn } from '@/lib/utils'
import { Key } from 'lucide-react'

const settingsTabs = [
  { id: 'subscription', label: 'Subscription', href: '/profile/settings' },
  { id: 'general', label: 'General', href: '/profile/settings/general' },
  { id: 'privacy', label: 'Privacy', href: '/profile/settings/privacy' },
  { id: 'security', label: 'Security', href: '/profile/settings/security' },
  { id: 'notifications', label: 'Notifications', href: '/profile/settings/notifications' },
  { id: 'customization', label: 'Customization', href: '/profile/settings/customization' },
  { id: 'api', label: 'API', href: '/profile/settings/api', icon: Key },
]

export default function SettingsLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const { user, loading } = useAuth()
  const router = useRouter()
  const pathname = usePathname()
  const [username, setUsername] = useState<string | null>(null)

  // Redirect to sign-in if not authenticated
  useEffect(() => {
    if (!loading && !user) {
      router.push('/auth/sign-in')
    }
  }, [user, loading, router])

  // Fetch username for the "View Public Profile" link
  useEffect(() => {
    const fetchUsername = async () => {
      if (!user) return
      
      const supabase = createClient()
      const { data } = await supabase
        .from('profiles')
        .select('username')
        .eq('id', user.id)
        .single()
      
      if (data) {
        setUsername(data.username)
      }
    }
    
    if (user) {
      fetchUsername()
    }
  }, [user])

  // Determine active tab based on pathname
  const getActiveTab = () => {
    if (pathname === '/profile/settings') return 'subscription'
    const segment = pathname.split('/').pop()
    return segment || 'subscription'
  }

  const activeTab = getActiveTab()

  if (loading) {
    return (
      <div className="container mx-auto py-8 max-w-4xl">
        <div className="flex items-center justify-center p-8">
          <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary" />
        </div>
      </div>
    )
  }

  if (!user) {
    return null
  }

  return (
    <div className="container mx-auto py-8 max-w-4xl">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-3xl font-bold">Profile Settings</h1>
        {username && (
          <Link
            href={`/profile/${username}`}
            className="rounded-md bg-primary px-3 py-2 text-sm font-semibold text-primary-foreground hover:bg-primary/90"
          >
            View Public Profile
          </Link>
        )}
      </div>
      
      {/* Tab Navigation */}
      <div className="mb-6">
        <nav 
          className="inline-flex h-10 items-center justify-center rounded-md bg-muted p-1 text-muted-foreground w-full"
          role="tablist"
        >
          {settingsTabs.map((tab) => {
            const isActive = activeTab === tab.id
            const Icon = tab.icon
            
            return (
              <Link
                key={tab.id}
                href={tab.href}
                role="tab"
                aria-selected={isActive}
                className={cn(
                  "inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 flex-1",
                  isActive 
                    ? "bg-background text-foreground shadow-sm" 
                    : "hover:bg-background/50 hover:text-foreground"
                )}
              >
                {Icon && <Icon className="h-3 w-3 mr-1" />}
                {tab.label}
              </Link>
            )
          })}
        </nav>
      </div>

      {/* Page Content */}
      <div className="space-y-6">
        {children}
      </div>
    </div>
  )
}

