# Requires `/lyt`  

# -------------------

# This module contains localized strings  
# (Note: OK, so it's not really i18n-like, since it's
# just a dictionary, but 'i18n' is short and sweet)

LYT.i18n = do ->
  
  # The strings themselves, as a hash
  strings =
    'Loading':                          'Indlæser'
    'Loading sound':                    'Henter lyd'
    'Logging in':                       'Logger ind'
    'Loading bookshelf':                'Indlæser boghylde'
    'Adding book to bookshelf':         'Tilføjer bog til boghylde'
    'Loading index':                    'Indlæser indholdsfortegnelse'
    'Loading bookmarks':                'Indlæser bogmærker'
    'Searching':                        'Søger'
    'Loading book':                     'Indlæser bog'
    'Suggestions':                      'Vi anbefaler'
    'Latest books':                     'Nyeste bøger'
    'Most popular':                     'Top 10 bøger'
    'Most popular - Kids':              'Top 10 - børn & unge'
    'Most popular - Adults':            'Top 10 - voksne'
    'Coming':                           'Kommer snart'
    'No bookmarks defined yet':         'Der er ingen bogmærker endnu' 
    'No search results':                'Din søgning gav ingen resultater, prøv igen'
    'Incorrect username or password':   'Forkert brugernavn eller kodeord'
    'Unable to retrieve book':          'Bogen kunne ikke hentes'
    'Try again':                        'Prøv igen'
    'Cancel':                           'Annuller'
    'Unable to retrieve sound file':    'Kunne ikke hente lydfilen'
    'Talking book':                     'Lydbog'
    'Talking book with text':           'Lydbog med tekst'
    'You are logged on as guest and hence can not remove books':       'Du er logget på som gæst og kan derfor ikke slette bøger'
    'Delete this book?':                'Vil du fjerne denne bog?'
    'Remove':                           'Fjern'
    'OK':                               'OK'
    'Remove book':                      'Fjern bog'
    'The end of the book':              'Her slutter bogen'
    'Bookmark location':                'Sæt bogmærke'
    'Unable to bookmark location':      'Kan ikke sætte bogmærke'
    'guest':                            'gæst'
    'New':                              'Ny'
    'Pending':                          'Undervejs'
    'Commercial':                       'Erhverv'
    'Listen to':                        'Hør'
    'by clicking this link':            'ved at følge dette link'
    'Comics':                           'Tegneserier'
    'Platform not supported':           'Platform ikke understøttet'
  
  # The i18n function. Returns either the translated string, or - if no
  # translation was found - the input string.
  (string) -> strings[string] or string

