// Supabase Edge Function: Generate Custom Bible Study
// This function orchestrates the LLM-based generation of a personalized 10-part Bible study

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get OpenAI API key
    const openAIKey = Deno.env.get('OPENAI_API_KEY')
    if (!openAIKey) {
      throw new Error('OPENAI_API_KEY not configured')
    }

    // Parse request body
    const { preference_id, user_id } = await req.json()

    if (!preference_id || !user_id) {
      return new Response(
        JSON.stringify({ error: 'preference_id and user_id are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`🎯 Starting study generation for user ${user_id}, preference ${preference_id}`)

    // 1. Fetch user preferences
    const preferencesResponse = await supabase
      .from('custom_study_preferences')
      .select('*')
      .eq('id', preference_id)
      .eq('user_id', user_id)
      .single()

    if (preferencesResponse.error || !preferencesResponse.data) {
      throw new Error(`Failed to fetch preferences: ${preferencesResponse.error?.message || 'No data returned'}`)
    }

    const preferences = preferencesResponse.data

    console.log('✅ Fetched preferences:', preferences)

    // 2. Run Classifier to get tags
    console.log('🏷️  Running classifier...')
    const tags = await runClassifier(openAIKey, preferences)
    console.log('✅ Classification complete:', tags)

    // 3. Run Planner to get 10-unit outline
    console.log('📋 Running planner...')
    const plan = await runPlanner(openAIKey, preferences, tags)
    console.log('✅ Plan complete:', plan.plan_title)

    // 4. Create the study record
    const studyResponse = await supabase
      .from('custom_studies')
      .insert({
        user_id,
        preference_id,
        title: plan.plan_title,
        description: plan.summary,
        total_units: 10,
        completed_units: 0,
        is_active: true,
      })
      .select()
      .single()

    if (studyResponse.error || !studyResponse.data) {
      throw new Error(`Failed to create study: ${studyResponse.error?.message || 'No data returned'}`)
    }

    const study = studyResponse.data

    console.log('✅ Created study:', study.id)

    // 5. Generate each unit and its sessions (in parallel for speed!)
    console.log('📚 Generating units and sessions...')
    const unitPromises = plan.units.map(async (unitOutline) => {
      const unitData = await generateUnit(openAIKey, unitOutline, preferences, supabase)
      return { unitOutline, unitData }
    })
    
    const unitsWithData = await Promise.all(unitPromises)
    
    for (const { unitOutline, unitData } of unitsWithData) {
      
      // Insert unit
      const unitResponse = await supabase
        .from('custom_study_units')
        .insert({
          study_id: study.id,
          unit_index: unitOutline.index - 1,
          unit_type: unitOutline.type,
          scope: unitOutline.scope,
          title: unitOutline.title,
          estimated_minutes: unitOutline.estimated_minutes,
          primary_passages: unitOutline.primary_passages,
          is_completed: false,
        })
        .select()
        .single()

      if (unitResponse.error || !unitResponse.data) {
        console.error(`❌ Failed to create unit ${unitOutline.index}:`, unitResponse.error)
        continue
      }

      const unit = unitResponse.data

      console.log(`✅ Created unit ${unitOutline.index}: ${unit.title}`)

      // Insert sessions for this unit
      for (const session of unitData.sessions) {
        const sessionResponse = await supabase
          .from('custom_study_sessions')
          .insert({
            unit_id: unit.id,
            session_index: session.session_index,
            title: session.title,
            estimated_minutes: session.estimated_minutes,
            passages: session.passages,
            context: session.context,
            key_insights: session.key_insights,
            reflection_questions: session.reflection_questions,
            prayer_prompt: session.prayer_prompt,
            action_step: session.action_step,
            memory_verse: session.memory_verse,
            cross_references: session.cross_references,
            is_completed: false,
          })

        if (sessionResponse.error) {
          console.error(`❌ Failed to create session ${session.session_index} for unit ${unitOutline.index}:`, sessionResponse.error)
        }
      }
    }

    console.log('🎉 Study generation complete!')

    return new Response(
      JSON.stringify({
        success: true,
        study_id: study.id,
        title: study.title,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('❌ Error generating study:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Classifier: Map user input to canonical tags
async function runClassifier(apiKey: string, preferences: any) {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-5-nano',
      reasoning_effort: 'minimal',
      messages: [
        {
          role: 'system',
          content: 'You classify Bible study interests. Output strict JSON only. Do not reveal your reasoning.'
        },
        {
          role: 'user',
          content: `Map these interests to known tags from this list: [hope, anxiety, peace, trust, suffering, grief, joy, prayer, holiness, justice, mercy, compassion, generosity, money, work, relationships, marriage, parenting, leadership, wisdom, creation, prophecy, mission, identity-in-Christ, forgiveness, spiritual-disciplines, apologetics].
Add up to 5 related tags.
Detect sensitivity topics: [trauma, abuse, addiction, grief].
Output schema:
{ "primary_tags": [...], "related_tags": [...], "sensitivity_flags": [...] }

User interests:
Goals: ${preferences.goals.join(', ')}
Topics: ${preferences.topics.join(', ')}`
        }
      ],
      response_format: { type: "json_object" }
    })
  })

  const data = await response.json()
  return JSON.parse(data.choices[0].message.content)
}

// Planner: Generate 10-unit curriculum outline
async function runPlanner(apiKey: string, preferences: any, tags: any) {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-5-nano',
      reasoning_effort: 'minimal',
      messages: [
        {
          role: 'system',
          content: 'You are a Bible study curriculum planner. Output strict JSON only. Do not reveal your reasoning.'
        },
        {
          role: 'user',
          content: `Respect user canon and translation constraints.
Mix genres (OT narrative/poetry/prophets; Gospels; Epistles).
By default, create 7 single-day units and 3 deep-dive units of 2–3 days.
Interleave topics aligned to tags; ramp difficulty gently.
Output schema:
{
 "plan_title": "string",
 "units": [
   {
     "index": 1,
     "type": "devotional|inductive|character|theme|word-study",
     "scope": "single-day|deep-dive-2days|deep-dive-3days",
     "title": "string",
     "primary_passages": ["Book ch:vs[-vs]"],
     "secondary_passages": ["Book ch:vs"],
     "estimated_minutes": number,
     "learning_goal": "string"
   }
 ],
 "summary": "≤80 words"
}

User Profile:
Goals: ${preferences.goals.join(', ')}
Topics: ${preferences.topics.join(', ')}
Minutes per session: ${preferences.minutes_per_session}
Reading level: ${preferences.reading_level}
Translation: ${preferences.translation}

Tags: ${JSON.stringify(tags)}`
        }
      ],
      response_format: { type: "json_object" }
    })
  })

  const data = await response.json()
  return JSON.parse(data.choices[0].message.content)
}

// Unit Builder: Generate detailed sessions for one unit (sessions in parallel!)
async function generateUnit(apiKey: string, unitOutline: any, preferences: any, supabase: any) {
  // Determine number of sessions based on scope
  const sessionCount = unitOutline.scope === 'single-day' ? 1 : 
                       unitOutline.scope === 'deep-dive-2days' ? 2 : 3

  // Generate all sessions in parallel for speed
  const sessionPromises = Array.from({ length: sessionCount }, async (_, i) => {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-5-nano',
        reasoning_effort: 'minimal',
        messages: [
          {
            role: 'system',
            content: 'You write Bible study sessions using retrieved Scripture/context. Output strict JSON only. Do not reveal your reasoning.'
          },
          {
            role: 'user',
            content: `Use the passages provided.
Reading level: ${preferences.reading_level}
Keep total words ≤ ${unitOutline.scope === 'single-day' ? 450 : 900}.
${preferences.include_discussion_questions ? 'Include discussion questions.' : 'Skip discussion questions.'}
Output schema:
{
 "session_meta": {
   "session_index": ${i},
   "title": "string",
   "estimated_minutes": number
 },
 "passages": ["Book ch:vs[-vs]"],
 "context": "≤100 words",
 "key_insights": ["• ...", "• ...", "• ..."],
 "reflection_questions": ["? ...", "? ...", "? ..."],
 "prayer_prompt": "2–4 sentences",
 "action_step": "1 imperative sentence",
 "memory_verse": "Book ch:vs",
 "cross_references": ["Book ch:vs", "..."]
}

Unit: ${unitOutline.title}
Goal: ${unitOutline.learning_goal}
Primary passages: ${unitOutline.primary_passages.join(', ')}
Session ${i + 1} of ${sessionCount}`
          }
        ],
        response_format: { type: "json_object" }
      })
    })

    const data = await response.json()
    const session = JSON.parse(data.choices[0].message.content)
    
    return {
      session_index: i,
      title: session.session_meta.title,
      estimated_minutes: session.session_meta.estimated_minutes,
      passages: session.passages,
      context: session.context,
      key_insights: session.key_insights,
      reflection_questions: session.reflection_questions || [],
      prayer_prompt: session.prayer_prompt,
      action_step: session.action_step,
      memory_verse: session.memory_verse || null,
      cross_references: session.cross_references || [],
    }
  })

  const sessions = await Promise.all(sessionPromises)

  return { sessions }
}

